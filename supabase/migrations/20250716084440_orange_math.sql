/*
  # Fix profile creation trigger for new users

  1. Problem
    - Users authenticate but don't get automatic profile entries
    - Notebooks table has foreign key constraint to profiles table
    - Creating notebooks fails due to missing profile entries

  2. Solution
    - Create trigger function to automatically create profile entries
    - Trigger executes after new user registration in auth.users
    - Ensures every authenticated user has a corresponding profile

  3. Security
    - Function uses SECURITY DEFINER to run with elevated privileges
    - Only creates profile entries for newly authenticated users
*/

-- Create or replace the trigger function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email)
  VALUES (new.id, new.email);
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if it exists to avoid conflicts
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create the trigger that fires after user creation
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();