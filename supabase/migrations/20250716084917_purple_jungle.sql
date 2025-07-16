/*
  # Fix profile creation trigger for new users

  1. Problem
    - Users can authenticate but don't automatically get profile entries
    - This causes foreign key constraint violations when creating notebooks
    - The notebooks table requires a valid user_id that exists in profiles table

  2. Solution
    - Create a trigger function that automatically creates profile entries
    - Trigger executes after new users are inserted into auth.users
    - Ensures every authenticated user has a corresponding profile record

  3. Security
    - Function uses SECURITY DEFINER to run with elevated privileges
    - Only creates profiles for newly authenticated users
    - Maintains data integrity between auth.users and profiles tables
*/

-- Create or replace the function that handles new user creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email)
  VALUES (NEW.id, NEW.email);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop the trigger if it exists to avoid conflicts
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create the trigger that automatically creates profiles for new users
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();