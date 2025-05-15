interface Range {
  min: string;
  max: string | null; // null means "no upper bound"
}

export interface Rule {
  range: Range;
  version: string;
}

function parse(ver: string): [number, number, number] {
  const parts = ver.split('.').map(Number);
  return [parts[0] ?? 0, parts[1] ?? 0, parts[2] ?? 0];
}

function compare(a: string, b: string): number {
  const [ay, am, ap] = parse(a);
  const [by, bm, bp] = parse(b);

  if (ay !== by) return ay - by;
  if (am !== bm) return am - bm;
  return ap - bp;
}

function isInRange(version: string, min: string, max: string | null): boolean {
  const aboveMin = compare(version, min) >= 0;
  const belowMax = max === null || compare(version, max) <= 0;
  return aboveMin && belowMax;
}

export function getDocsVersion(rules: Rule[], version: string): string | null {
  const rule = rules.find(({ range }) =>
    isInRange(version, range.min, range.max)
  );
  return rule?.version ?? null;
}
