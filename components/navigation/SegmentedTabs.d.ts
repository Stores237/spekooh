export interface SegmentedTabsProps {
  options: string[];
  active: number;
  onChange: (index: number) => void;
}
