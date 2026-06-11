---
name: Maroon & Cream Editorial
colors:
  surface: '#fbf9f8'
  surface-dim: '#dbd9d9'
  surface-bright: '#fbf9f8'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f5f3f3'
  surface-container: '#efeded'
  surface-container-high: '#eae8e7'
  surface-container-highest: '#e4e2e2'
  on-surface: '#1b1c1c'
  on-surface-variant: '#5a413d'
  inverse-surface: '#303030'
  inverse-on-surface: '#f2f0f0'
  outline: '#8e706c'
  outline-variant: '#e2bfb9'
  surface-tint: '#b22b1d'
  primary: '#570000'
  on-primary: '#ffffff'
  primary-container: '#800000'
  on-primary-container: '#ff8371'
  inverse-primary: '#ffb4a8'
  secondary: '#5e5e5b'
  on-secondary: '#ffffff'
  secondary-container: '#e1dfdb'
  on-secondary-container: '#63635f'
  tertiary: '#735c00'
  on-tertiary: '#ffffff'
  tertiary-container: '#cba72f'
  on-tertiary-container: '#4e3d00'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdad4'
  primary-fixed-dim: '#ffb4a8'
  on-primary-fixed: '#410000'
  on-primary-fixed-variant: '#8f0f07'
  secondary-fixed: '#e4e2dd'
  secondary-fixed-dim: '#c8c6c2'
  on-secondary-fixed: '#1b1c19'
  on-secondary-fixed-variant: '#474744'
  tertiary-fixed: '#ffe088'
  tertiary-fixed-dim: '#e9c349'
  on-tertiary-fixed: '#241a00'
  on-tertiary-fixed-variant: '#574500'
  background: '#fbf9f8'
  on-background: '#1b1c1c'
  surface-variant: '#e4e2e2'
typography:
  display-lg:
    fontFamily: Montserrat
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Montserrat
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
  headline-lg-mobile:
    fontFamily: Montserrat
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 36px
  headline-md:
    fontFamily: Montserrat
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-lg:
    fontFamily: Montserrat
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Montserrat
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-md:
    fontFamily: Montserrat
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.05em
  caption:
    fontFamily: Montserrat
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  xs: 4px
  sm: 12px
  md: 24px
  lg: 40px
  xl: 64px
  margin-mobile: 20px
  gutter-mobile: 16px
---

## Brand & Style

The design system is anchored in a sophisticated, modern aesthetic that balances the gravity of deep maroon with the lightness of soft cream. It is designed for high-end editorial, luxury retail, or professional services where authority and elegance are paramount. 

The style utilizes a **Modern Corporate** foundation infused with **Minimalist** and **Editorial** influences. It prioritizes generous whitespace to allow content to breathe, creating a calm yet commanding user experience. The emotional response is one of trust, exclusivity, and refined taste.

## Colors

The palette is dominated by **Granate (Deep Maroon)**, used strategically for primary actions and brand identifiers. 

- **Primary (#800000):** Used for key buttons, active states, and high-level headings.
- **Secondary (#F9F7F2):** A soft cream used as the main background surface to reduce eye strain and provide a premium feel compared to pure white.
- **Accent Gold (#D4AF37):** Reserved for subtle highlights, icons, or premium indicators. 
- **Neutral Grey (#4A4A4A):** Used for body text and secondary labels to maintain legibility without the harshness of pure black.
- **Surface Tint (#EBE7DF):** A slightly darker cream for borders, dividers, and input backgrounds.

## Typography

**Montserrat** is the sole typeface used throughout the design. Its geometric and versatile character works equally well for headlines, body text, labels, and UI elements. By using a range of weights (light for body, semibold for labels, bold for headlines) a clear hierarchy is achieved without needing a secondary font. Headlines should use tighter letter-spacing to feel more cohesive. Labels are set in semi-bold with slight tracking and uppercase styling to distinguish them from body content.

## Layout & Spacing

The design system employs a **Fluid Grid** model optimized for mobile-first delivery. 

- **Rhythm:** An 8px base unit governs all spatial relationships.
- **Margins:** Mobile layouts utilize a 20px side margin to ensure content does not feel cramped against the bezel.
- **Sectioning:** Large vertical spacing (40px to 64px) is used between major content blocks to emphasize the minimalist, "breathing" luxury aesthetic.
- **Alignment:** Center-alignment is preferred for hero headlines and primary call-to-actions, while standard content remains left-aligned for readability.

## Elevation & Depth

Hierarchy is established through **Tonal Layers** and **Ambient Shadows**. 

Surfaces are generally flat or use a very subtle "Surface-over-Surface" approach. When depth is required (e.g., for floating cards or primary buttons), shadows should be extremely soft and diffused:
- **Shadow Color:** #800000 at 4-6% opacity for a subtle maroon-tinted depth.
- **Blur:** High blur radius (16px to 24px) with low spread to avoid a "heavy" or "dirty" look.
- **Dividers:** Use 1px solid strokes in the Surface Tint color (#EBE7DF) instead of shadows whenever possible to maintain a clean, architectural feel.

## Shapes

The shape language is defined by **Rounded** corners that soften the authoritative nature of the maroon color and serif typography. 

- **Standard Elements:** Buttons, inputs, and small cards use a 0.5rem (8px) radius.
- **Large Containers:** Content sections or modal sheets use a 1rem (16px) radius to feel more approachable.
- **Interactive States:** Subtle transitions in background color are preferred over shape changes during interaction.

## Components

### Buttons
Primary buttons are solid Deep Maroon (#800000) with white text. Secondary buttons use a maroon outline with maroon text. High-emphasis "Gold" buttons may be used for exclusive features. All buttons have 0.5rem rounded corners and generous horizontal padding.

### Input Fields
Inputs use the Surface Tint background (#EBE7DF) with no border in their default state. Upon focus, they transition to a 1px solid Maroon border. Labels are positioned above the field in uppercase Label-MD typography.

### Cards
Cards are styled with the Soft Cream secondary color, using a subtle 1px border (#EBE7DF) or a very soft ambient shadow to separate them from the background. They feature a 1rem corner radius for a modern feel.

### Chips & Tags
Used for categorization, chips are styled with a light grey background and dark grey text. For "Active" categories, use a Deep Maroon background with white text.

### Lists
List items are separated by thin 1px dividers. Use ample vertical padding (16px - 24px) to maintain the editorial rhythm. Navigation arrows should be thin and elegant.
