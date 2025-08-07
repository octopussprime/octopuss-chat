# RTL and Arabic Language Support

This application now supports Right-to-Left (RTL) languages, specifically Arabic, along with the existing English support.

## Features Added

### 1. Internationalization (i18n)
- **react-i18next** for translation management
- **i18next-browser-languagedetector** for automatic language detection
- Language files in `src/locales/` for English (`en.json`) and Arabic (`ar.json`)

### 2. Language Context
- `LanguageContext` in `src/contexts/LanguageContext.tsx` manages:
  - Current language state
  - RTL detection and direction management
  - Language switching functionality
  - Document direction and lang attribute updates

### 3. Language Switcher Component
- Located in `src/components/language/LanguageSwitcher.tsx`
- Dropdown menu with language options
- Shows native language names (English, العربية)
- RTL-aware positioning

### 4. RTL Support
- **CSS**: Added RTL-specific styles and utilities in `src/index.css`
- **Fonts**: Google Fonts integration for Arabic (Noto Sans Arabic)
- **Tailwind**: Updated configuration with RTL plugin and Arabic font family
- **Utilities**: RTL-aware utility functions in `src/lib/rtl-utils.ts`

### 5. Updated Components
- **App.tsx**: Added LanguageProvider wrapper
- **DashboardHeader**: Integrated language switcher and RTL support
- **Dashboard**: Added translation support and RTL styling

## Usage

### Using Translations
```tsx
import { useTranslation } from 'react-i18next';

const MyComponent = () => {
  const { t } = useTranslation();
  
  return (
    <div>
      <h1>{t('dashboard.welcome')}</h1>
      <button>{t('common.save')}</button>
    </div>
  );
};
```

### Using RTL Context
```tsx
import { useLanguage } from '@/contexts/LanguageContext';

const MyComponent = () => {
  const { isRTL, direction, changeLanguage } = useLanguage();
  
  return (
    <div className={`${isRTL ? 'text-right' : 'text-left'}`}>
      <p>Current direction: {direction}</p>
      <button onClick={() => changeLanguage('ar')}>
        Switch to Arabic
      </button>
    </div>
  );
};
```

### RTL-Aware Styling
```tsx
import { useLanguage } from '@/contexts/LanguageContext';

const MyComponent = () => {
  const { isRTL } = useLanguage();
  
  return (
    <div className={`flex items-center ${isRTL ? 'space-x-reverse' : ''} space-x-4`}>
      <span>Item 1</span>
      <span>Item 2</span>
    </div>
  );
};
```

## CSS Classes for RTL

### Spacing
- `space-x-reverse`: Reverses horizontal spacing in RTL
- `divide-x-reverse`: Reverses horizontal dividers in RTL

### Text Alignment
- `text-start`: Aligns text to the start (left in LTR, right in RTL)
- `text-end`: Aligns text to the end (right in LTR, left in RTL)

### Margins and Padding
- `ms-auto`: Margin inline start auto
- `me-auto`: Margin inline end auto
- `ps-4`: Padding inline start
- `pe-4`: Padding inline end

### Borders
- `border-s`: Border inline start
- `border-e`: Border inline end
- `rounded-s-lg`: Rounded corners inline start
- `rounded-e-lg`: Rounded corners inline end

## Adding New Languages

1. Create a new JSON file in `src/locales/` (e.g., `fr.json`)
2. Add translations following the existing structure
3. Update the `resources` object in `src/locales/i18n.ts`
4. Add the language to the `languages` array in `LanguageSwitcher.tsx`
5. If the language is RTL, add it to the `RTL_LANGUAGES` array in `LanguageContext.tsx`

## Translation Keys Structure

```json
{
  "common": {
    "loading": "Loading...",
    "error": "Error",
    "save": "Save",
    // ... other common keys
  },
  "navigation": {
    "dashboard": "Dashboard",
    "settings": "Settings",
    // ... navigation keys
  },
  "auth": {
    "signIn": "Sign In",
    "signOut": "Sign Out",
    // ... auth keys
  }
  // ... other sections
}
```

## Browser Support

The RTL support uses modern CSS features:
- CSS Logical Properties (`margin-inline-start`, `padding-inline-end`, etc.)
- `dir` attribute for document direction
- CSS Grid and Flexbox RTL support

## Testing RTL

1. Use the language switcher in the header to switch to Arabic
2. Observe the layout changes:
   - Text alignment switches to right
   - Spacing and margins flip
   - Icons and UI elements reposition appropriately
3. Test with browser developer tools by changing the `dir` attribute manually

## Performance Considerations

- Language files are loaded on demand
- Font loading is optimized with `font-display: swap`
- Language preference is stored in localStorage
- Minimal bundle size impact with tree-shaking

## Accessibility

- Proper `lang` attribute is set on the document
- `dir` attribute is correctly applied
- Screen readers will announce content in the correct language
- Keyboard navigation works correctly in both directions