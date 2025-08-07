import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from '@/contexts/AuthContext';
import { useNotebookGeneration } from './useNotebookGeneration';
import { useEffect } from 'react';

export const useSources = (notebookId?: string) => {
  const { user } = useAuth();
  const queryClient = useQueryClient();
  const { generateNotebookContentAsync } = useNotebookGeneration();

  const {
    data: sources = [],
    isLoading,
    error,
  } = useQuery({
    queryKey: ['sources', notebookId],
    queryFn: async () => {
      if (!notebookId) return [];
      
      const { data, error } = await supabase
        .from('sources')
        .select('*')
        .eq('notebook_id', notebookId)
        .order('created_at', { ascending: false });

      if (error) throw error;
      return data;
    },
    enabled: !!notebookId,
  });

  // Set up Realtime subscription for sources table
  useEffect(() => {
    if (!notebookId || !user) return;

    console.log('Setting up Realtime subscription for sources table, notebook:', notebookId);

    const channel = supabase
      .channel('sources-changes')
      .on(
        'postgres_changes',
        {
          event: '*', // Listen to all events (INSERT, UPDATE, DELETE)
          schema: 'public',
          table: 'sources',
          filter: `notebook_id=eq.${notebookId}`
        },
        (payload: any) => {
          console.log('Realtime: Sources change received:', payload);
          
          // Update the query cache based on the event type
          queryClient.setQueryData(['sources', notebookId], (oldSources: any[] = []) => {
            switch (payload.eventType) {
              case 'INSERT':
                // Add new source if it doesn't already exist
                const newSource = payload.new as any;
                const existsInsert = oldSources.some(source => source.id === newSource?.id);
                if (existsInsert) {
                  console.log('Source already exists, skipping INSERT:', newSource?.id);
                  return oldSources;
                }
                console.log('Adding new source to cache:', newSource);
                return [newSource, ...oldSources];
                
              case 'UPDATE':
                // Update existing source
                const updatedSource = payload.new as any;
                console.log('Updating source in cache:', updatedSource?.id);
                return oldSources.map(source => 
                  source.id === updatedSource?.id ? updatedSource : source
                );
                
              case 'DELETE':
                // Remove deleted source
                const deletedSource = payload.old as any;
                console.log('Removing source from cache:', deletedSource?.id);
                return oldSources.filter(source => source.id !== deletedSource?.id);
                
              default:
                console.log('Unknown event type:', payload.eventType);
                return oldSources;
            }
          });
        }
      )
      .subscribe((status) => {
        console.log('Realtime subscription status for sources:', status);
      });

    return () => {
      console.log('Cleaning up Realtime subscription for sources');
      supabase.removeChannel(channel);
    };
  }, [notebookId, user, queryClient]);

  // Helper function to check if notebook generation should be triggered
  const shouldTriggerGeneration = async (source: any, isFirstSource: boolean) => {
    if (!isFirstSource || !notebookId) return false;

    // Check notebook generation status
    const { data: notebook } = await supabase
      .from('notebooks')
      .select('generation_status')
      .eq('id', notebookId)
      .single();
    
    if (notebook?.generation_status !== 'pending') return false;

    // Check if source has required data for generation
    const canGenerate = 
      (source.type === 'pdf' && source.file_path) ||
      (source.type === 'text' && source.content) ||
      (source.type === 'website' && source.url) ||
      (source.type === 'youtube' && source.url) ||
      (source.type === 'audio' && source.file_path);

    return canGenerate;
  };

  const addSource = useMutation({
    mutationFn: async (sourceData: {
      notebookId: string;
      title: string;
      type: 'pdf' | 'text' | 'website' | 'youtube' | 'audio';
      content?: string;
      url?: string;
      file_path?: string;
      file_size?: number;
      processing_status?: string;
      metadata?: any;
    }) => {
      if (!user) throw new Error('User not authenticated');

      const { data, error } = await supabase
        .from('sources')
        .insert({
          notebook_id: sourceData.notebookId,
          title: sourceData.title,
          type: sourceData.type,
          content: sourceData.content,
          url: sourceData.url,
          file_path: sourceData.file_path,
          file_size: sourceData.file_size,
          processing_status: sourceData.processing_status,
          metadata: sourceData.metadata || {},
        })
        .select()
        .single();

      if (error) throw error;
      return data;
    },
    onSuccess: async (newSource) => {
      console.log('Source added successfully:', newSource);
      
      // The Realtime subscription will handle updating the cache
      // Check if this is the first source and trigger generation if needed
      const currentSources = queryClient.getQueryData(['sources', notebookId]) as any[] || [];
      const isFirstSource = currentSources.length === 0;
      
      if (await shouldTriggerGeneration(newSource, isFirstSource)) {
        console.log('Triggering notebook content generation for first source...');
        
        try {
          await generateNotebookContentAsync({
            notebookId: notebookId!,
            filePath: newSource.file_path || newSource.url,
            sourceType: newSource.type
          });
        } catch (error) {
          console.error('Failed to generate notebook content:', error);
        }
      }
    },
  });

  const updateSource = useMutation({
    mutationFn: async ({ sourceId, updates }: { 
      sourceId: string; 
      updates: { 
        title?: string;
        file_path?: string;
        processing_status?: string;
      }
    }) => {
      const { data, error } = await supabase
        .from('sources')
        .update(updates)
        .eq('id', sourceId)
        .select()
        .single();

      if (error) throw error;
      return data;
    },
    onSuccess: async (updatedSource) => {
      // The Realtime subscription will handle updating the cache
      
      // Only trigger generation if file_path was added and this is the first source
      if (updatedSource.file_path && notebookId) {
        const currentSources = queryClient.getQueryData(['sources', notebookId]) as any[] || [];
        const isFirstSource = currentSources.length === 1;
        
        if (await shouldTriggerGeneration(updatedSource, isFirstSource)) {
          console.log('File path updated, triggering notebook content generation...');
          
          try {
            await generateNotebookContentAsync({
              notebookId,
              filePath: updatedSource.file_path,
              sourceType: updatedSource.type
            });
          } catch (error) {
            console.error('Failed to generate notebook content:', error);
          }
        }
      }
    },
  });

  return {
    sources,
    isLoading,
    error,
    addSource: addSource.mutate,
    addSourceAsync: addSource.mutateAsync,
    isAdding: addSource.isPending,
    updateSource: updateSource.mutate,
    isUpdating: updateSource.isPending,
  };
};