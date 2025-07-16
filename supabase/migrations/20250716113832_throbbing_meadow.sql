/*
  # Create notebooks table and related schema

  1. New Tables
    - `notebooks`
      - `id` (uuid, primary key)
      - `title` (text)
      - `user_id` (uuid, foreign key to auth.users)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)
    - `sources`
      - `id` (uuid, primary key)
      - `notebook_id` (uuid, foreign key to notebooks)
      - `title` (text)
      - `content` (text)
      - `source_type` (enum: pdf, text, website, youtube, audio)
      - `file_url` (text, optional)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)
    - `notes`
      - `id` (uuid, primary key)
      - `notebook_id` (uuid, foreign key to notebooks)
      - `title` (text)
      - `content` (text)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)
    - `chat_messages`
      - `id` (uuid, primary key)
      - `notebook_id` (uuid, foreign key to notebooks)
      - `message` (text)
      - `response` (text)
      - `sources` (jsonb, optional)
      - `created_at` (timestamp)

  2. Security
    - Enable RLS on all tables
    - Add policies for authenticated users to access their own data

  3. Functions
    - Add trigger function to update updated_at columns
    - Add trigger function to handle new user creation
*/

-- Create source_type enum if it doesn't exist
DO $$ BEGIN
    CREATE TYPE source_type AS ENUM ('pdf', 'text', 'website', 'youtube', 'audio');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Create notebooks table
CREATE TABLE IF NOT EXISTS notebooks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL DEFAULT 'Untitled Notebook',
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  created_at timestamptz DEFAULT now() NOT NULL,
  updated_at timestamptz DEFAULT now() NOT NULL
);

-- Create sources table
CREATE TABLE IF NOT EXISTS sources (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  notebook_id uuid REFERENCES notebooks(id) ON DELETE CASCADE NOT NULL,
  title text NOT NULL,
  content text,
  source_type source_type NOT NULL,
  file_url text,
  created_at timestamptz DEFAULT now() NOT NULL,
  updated_at timestamptz DEFAULT now() NOT NULL
);

-- Create notes table
CREATE TABLE IF NOT EXISTS notes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  notebook_id uuid REFERENCES notebooks(id) ON DELETE CASCADE NOT NULL,
  title text NOT NULL DEFAULT 'Untitled Note',
  content text DEFAULT '',
  created_at timestamptz DEFAULT now() NOT NULL,
  updated_at timestamptz DEFAULT now() NOT NULL
);

-- Create chat_messages table
CREATE TABLE IF NOT EXISTS chat_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  notebook_id uuid REFERENCES notebooks(id) ON DELETE CASCADE NOT NULL,
  message text NOT NULL,
  response text,
  sources jsonb,
  created_at timestamptz DEFAULT now() NOT NULL
);

-- Create audio_overviews table for podcast generation
CREATE TABLE IF NOT EXISTS audio_overviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  notebook_id uuid REFERENCES notebooks(id) ON DELETE CASCADE NOT NULL,
  audio_url text,
  status text DEFAULT 'pending',
  created_at timestamptz DEFAULT now() NOT NULL,
  updated_at timestamptz DEFAULT now() NOT NULL
);

-- Enable Row Level Security
ALTER TABLE notebooks ENABLE ROW LEVEL SECURITY;
ALTER TABLE sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE audio_overviews ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for notebooks
CREATE POLICY "Users can read own notebooks"
  ON notebooks
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own notebooks"
  ON notebooks
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own notebooks"
  ON notebooks
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own notebooks"
  ON notebooks
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- Create RLS policies for sources
CREATE POLICY "Users can read sources from own notebooks"
  ON sources
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM notebooks 
      WHERE notebooks.id = sources.notebook_id 
      AND notebooks.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert sources to own notebooks"
  ON sources
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM notebooks 
      WHERE notebooks.id = sources.notebook_id 
      AND notebooks.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update sources in own notebooks"
  ON sources
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM notebooks 
      WHERE notebooks.id = sources.notebook_id 
      AND notebooks.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete sources from own notebooks"
  ON sources
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM notebooks 
      WHERE notebooks.id = sources.notebook_id 
      AND notebooks.user_id = auth.uid()
    )
  );

-- Create RLS policies for notes
CREATE POLICY "Users can read notes from own notebooks"
  ON notes
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM notebooks 
      WHERE notebooks.id = notes.notebook_id 
      AND notebooks.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert notes to own notebooks"
  ON notes
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM notebooks 
      WHERE notebooks.id = notes.notebook_id 
      AND notebooks.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update notes in own notebooks"
  ON notes
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM notebooks 
      WHERE notebooks.id = notes.notebook_id 
      AND notebooks.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete notes from own notebooks"
  ON notes
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM notebooks 
      WHERE notebooks.id = notes.notebook_id 
      AND notebooks.user_id = auth.uid()
    )
  );

-- Create RLS policies for chat_messages
CREATE POLICY "Users can read chat messages from own notebooks"
  ON chat_messages
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM notebooks 
      WHERE notebooks.id = chat_messages.notebook_id 
      AND notebooks.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert chat messages to own notebooks"
  ON chat_messages
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM notebooks 
      WHERE notebooks.id = chat_messages.notebook_id 
      AND notebooks.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update chat messages in own notebooks"
  ON chat_messages
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM notebooks 
      WHERE notebooks.id = chat_messages.notebook_id 
      AND notebooks.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete chat messages from own notebooks"
  ON chat_messages
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM notebooks 
      WHERE notebooks.id = chat_messages.notebook_id 
      AND notebooks.user_id = auth.uid()
    )
  );

-- Create RLS policies for audio_overviews
CREATE POLICY "Users can read audio overviews from own notebooks"
  ON audio_overviews
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM notebooks 
      WHERE notebooks.id = audio_overviews.notebook_id 
      AND notebooks.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert audio overviews to own notebooks"
  ON audio_overviews
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM notebooks 
      WHERE notebooks.id = audio_overviews.notebook_id 
      AND notebooks.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update audio overviews in own notebooks"
  ON audio_overviews
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM notebooks 
      WHERE notebooks.id = audio_overviews.notebook_id 
      AND notebooks.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete audio overviews from own notebooks"
  ON audio_overviews
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM notebooks 
      WHERE notebooks.id = audio_overviews.notebook_id 
      AND notebooks.user_id = auth.uid()
    )
  );

-- Create trigger function to update updated_at column
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_notebooks_updated_at 
    BEFORE UPDATE ON notebooks 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sources_updated_at 
    BEFORE UPDATE ON sources 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_notes_updated_at 
    BEFORE UPDATE ON notes 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_audio_overviews_updated_at 
    BEFORE UPDATE ON audio_overviews 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create function to handle new user creation
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- You can add any user initialization logic here
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for new user creation
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();