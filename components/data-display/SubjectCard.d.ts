export interface SubjectCardProps {
  icon: React.ReactNode;
  title: string;
  subtitle?: string;
  badgeText?: string;
  code?: string;
  onClick?: () => void;
}
