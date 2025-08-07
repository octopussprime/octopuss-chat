import React, { createContext, useContext, useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';

interface LanguageContextType {
  language: string;
  isRTL: boolean;
  changeLanguage: (lang: string) => void;
  direction: 'ltr' | 'rtl';
}

const LanguageContext = createContext<LanguageContextType | undefined>(undefined);

export const useLanguage = () => {
  const context = useContext(LanguageContext);
  if (!context) {
    throw new Error('useLanguage must be used within a LanguageProvider');
  }
  return context;
};

interface LanguageProviderProps {
  children: React.ReactNode;
}

const RTL_LANGUAGES = ['ar', 'he', 'fa', 'ur'];

export const LanguageProvider: React.FC<LanguageProviderProps> = ({ children }) => {
  const { i18n } = useTranslation();
  const [language, setLanguage] = useState(i18n.language || 'en');
  const [isRTL, setIsRTL] = useState(RTL_LANGUAGES.includes(i18n.language || 'en'));

  const changeLanguage = async (lang: string) => {
    await i18n.changeLanguage(lang);
    setLanguage(lang);
    setIsRTL(RTL_LANGUAGES.includes(lang));
    
    // Update document direction and lang attribute
    document.documentElement.dir = RTL_LANGUAGES.includes(lang) ? 'rtl' : 'ltr';
    document.documentElement.lang = lang;
    
    // Store in localStorage
    localStorage.setItem('language', lang);
  };

  useEffect(() => {
    // Set initial direction and language
    const currentLang = i18n.language || 'en';
    const isCurrentRTL = RTL_LANGUAGES.includes(currentLang);
    
    document.documentElement.dir = isCurrentRTL ? 'rtl' : 'ltr';
    document.documentElement.lang = currentLang;
    
    setLanguage(currentLang);
    setIsRTL(isCurrentRTL);
  }, [i18n.language]);

  const direction = isRTL ? 'rtl' : 'ltr';

  const value: LanguageContextType = {
    language,
    isRTL,
    changeLanguage,
    direction,
  };

  return (
    <LanguageContext.Provider value={value}>
      {children}
    </LanguageContext.Provider>
  );
};