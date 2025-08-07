import { useTranslation } from 'react-i18next';
import { Button } from '@/components/ui/button';
import { User, LogOut } from 'lucide-react';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '@/components/ui/dropdown-menu';
import { useLogout } from '@/services/authService';
import { LanguageSwitcher } from '@/components/language';
import { useLanguage } from '@/contexts/LanguageContext';
import Logo from '@/components/ui/Logo';

interface DashboardHeaderProps {
  userEmail?: string;
}

const DashboardHeader = ({ userEmail }: DashboardHeaderProps) => {
  const { logout } = useLogout();
  const { t } = useTranslation();
  const { isRTL } = useLanguage();

  return (
    <header className="bg-white px-6 py-4">
      <div className="flex items-center justify-between">
        <div className={`flex items-center ${isRTL ? 'space-x-reverse' : ''} space-x-2`}>
          <Logo />
          <h1 className="text-xl font-medium text-gray-900">Mission Control</h1>
        </div>
        
        <div className={`flex items-center ${isRTL ? 'space-x-reverse' : ''} space-x-4`}>
          <LanguageSwitcher />
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="ghost" size="sm" className="p-0">
                <div className="w-8 h-8 bg-purple-500 rounded-full flex items-center justify-center cursor-pointer hover:bg-purple-600 transition-colors">
                  <User className="h-4 w-4 text-white" />
                </div>
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align={isRTL ? 'start' : 'end'} className="w-48">
              <DropdownMenuItem onClick={logout} className="cursor-pointer">
                <LogOut className={`h-4 w-4 ${isRTL ? 'ml-2' : 'mr-2'}`} />
                {t('auth.signOut')}
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        </div>
      </div>
    </header>
  );
};

export default DashboardHeader;