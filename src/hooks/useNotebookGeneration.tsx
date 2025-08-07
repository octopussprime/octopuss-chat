import { useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { useToast } from '@/hooks/use-toast';

// Track notebooks that are currently generating content to prevent duplicates
const generatingNotebooks = new Set<string>();

// Debug function to check current state (can be removed in production)
export const getGeneratingNotebooks = () => Array.from(generatingNotebooks);

export const useNotebookGeneration = () => {
  const queryClient = useQueryClient();
  const { toast } = useToast();

  const generateNotebookContent = useMutation({
    mutationFn: async ({ notebookId, filePath, sourceType }: { 
      notebookId: string; 
      filePath?: string;
      sourceType: string;
    }) => {
      // Check if this notebook is already being processed
      if (generatingNotebooks.has(notebookId)) {
        console.log('Notebook content generation already in progress for:', notebookId);
        throw new Error('Generation already in progress');
      }

      // Add to tracking set
      generatingNotebooks.add(notebookId);

      console.log('Starting notebook content generation for:', notebookId, 'with source type:', sourceType);
      console.log('Currently generating notebooks:', Array.from(generatingNotebooks));
      
      try {
        const { data, error } = await supabase.functions.invoke('generate-notebook-content', {
          body: {
            notebookId,
            filePath,
            sourceType
          }
        });

        if (error) {
          console.error('Edge function error:', error);
          throw error;
        }

        return data;
      } finally {
        // Always remove from tracking set when done
        generatingNotebooks.delete(notebookId);
        console.log('Notebook generation completed/failed for:', notebookId);
        console.log('Remaining generating notebooks:', Array.from(generatingNotebooks));
      }
    },
    onSuccess: (data) => {
      console.log('Notebook generation successful:', data);
      
      // Invalidate relevant queries to refresh the UI
      queryClient.invalidateQueries({ queryKey: ['notebooks'] });
      queryClient.invalidateQueries({ queryKey: ['notebook'] });
      
      toast({
        title: "Content Generated",
        description: "Notebook title and description have been generated successfully.",
      });
    },
    onError: (error) => {
      console.error('Notebook generation failed:', error);
      
      // Only show toast for actual errors, not for "already in progress" errors
      if (!error.message?.includes('Generation already in progress')) {
        toast({
          title: "Generation Failed",
          description: "Failed to generate notebook content. Please try again.",
          variant: "destructive",
        });
      }
    },
  });

  return {
    generateNotebookContent: generateNotebookContent.mutate,
    generateNotebookContentAsync: generateNotebookContent.mutateAsync,
    isGenerating: generateNotebookContent.isPending,
  };
};