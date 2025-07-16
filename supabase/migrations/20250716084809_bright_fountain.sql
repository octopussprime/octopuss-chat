/*
  # Fix profile creation trigger for new users

  1. New Functions
    - `handle_new_user()` - Automatically creates a profile entry when a new user signs up

  2. Security
    - Creates trigger to automatically insert profile records for new users
    - Ensures foreign key constraint is satisfied when creating notebooks

  3. Changes
    - Adds automatic profile creation for all new authenticated users
    - Fixes foreign key constraint violation error when creating notebooks
*/

-- Drop existing trigger if it exists to avoid conflicts
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Create function to handle new user profile creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email)
  VALUES (NEW.id, NEW.email);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to automatically create profile when user signs up
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();