/** Simplified Alfa-Bank mark: the letter "A" over a bar. Colour comes from `currentColor`. */
export function AlfaLogo({ size = 28 }: { size?: number }) {
  return (
    <svg className="logo" width={size} height={size} viewBox="0 0 24 24" aria-hidden="true">
      <path
        fill="currentColor"
        fillRule="evenodd"
        d="M9.5 2h5l6 15.5h-4.2l-1.3-3.6H9l-1.3 3.6H3.5L9.5 2Zm2.5 4.4-1.9 5.3h3.8L12 6.4Z"
      />
      <rect fill="currentColor" x="3.5" y="19.2" width="17" height="2.8" />
    </svg>
  );
}
