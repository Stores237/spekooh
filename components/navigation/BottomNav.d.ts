export interface BottomNavItem {
  icon: React.ReactNode;
  label?: string;
  center?: boolean;
}
export interface BottomNavProps {
  items: BottomNavItem[];
  active: number;
  onChange: (index: number) => void;
}
