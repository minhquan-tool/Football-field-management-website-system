# FC-UTE — UI/UX Pro Max implementation

Scope: existing HTML/CSS/JavaScript + Spring Boot static resources. No new framework, CDN, font dependency, routing policy or database change.

Direction: sports booking with a calm operations workspace. Keep the blue FC-UTE identity and bundled Montserrat; supplement with system sans-serif. Skill searches verified hero/CTA hierarchy, flat app surfaces, responsive spacing, visible focus and labelled forms. Suggested red/teal palettes and editorial fonts were rejected as a poor match for the existing brand and Vietnamese operations UI.

Tokens: primary #1d4ed8, primary-hover #1e40af, ink #14243b, muted #526279, border #dbe4ef, canvas #f3f6fb, surface #ffffff. Navy #132c54 on staff sidebar. Semantic success #176344 on #e5f5ee, warning #87570a on #fff4d6, danger #b42332 on #fff0f0. Do not communicate status with color alone.

Typography: bundled Montserrat, Arial, sans-serif. Body, inputs and actions 16px; table data, labels and supporting text 14px; role navigation 15px. Workspace headings 28–32px, section headings 22px, subheadings 20px, key financial totals 28–36px. Weekly calendar uses 108px/hour and 152px event lanes to accommodate readable 14px event text. Line-height 1.5–1.65. Heading hierarchy, no all-caps paragraphs.

Spacing: 4/8px rhythm, 16/24/32px sections; 44px minimum controls; 12px corner controls, 16px cards. Use calm borders with restrained shadows. Avoid extra motion/dependencies.

Navigation: customer horizontal bar remains horizontal on desktop on every page. Staff/accountant/manager sidebar stays consistent by authenticated role. Mobile menu uses existing toggle and policy. Preserve link destinations and permissions.

Pages: public homepage uses an editorial blue hero, local SVG pitch and a prominent real-data search panel; auth uses a two-column brand/form layout on wide screens and a single form on mobile; internal screens use navy sidebar, clear header, grouped white content surfaces, readable financial data and scroll-contained tables.

Accessibility: visible labels, safe icon padding, keyboard-visible focus, skip-to-content link, 44px targets, responsive 375/768/1024/1440; no document overflow. Table/schedule horizontal scroll stays inside named regions. Respect reduced motion and print layouts. Keep errors, loading/disabled states and real API values.

Implementation: frontend/css/experience.css is the presentation layer after existing shared CSS. Keep IDs, names, form listeners and API calls. Never turn a failed API into a visual success.
