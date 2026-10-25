// 'warehouse' and 'fa-car' get the solid style, a full 'fa-regular fa-car' stays as it is
export function resolveIconClass(icon?: string): string {
  if (!icon) return ''
  if (/^fa-(solid|regular|brands|light|thin|duotone) /.test(icon)) return icon
  if (icon.startsWith('fa-')) return 'fa-solid ' + icon
  return 'fa-solid fa-' + icon
}
