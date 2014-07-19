# Maintainer: Caedus <caedus75@gmail.com>

pkgname=script-backup
_realname=backup
pkgver=2.2.0
pkgrel=1
pkgdesc="Script para backup dos meu arquivos pessoais"
arch=('any')
license=('GPL3')
depends=('rsync')
source=('backup.conf' 'backup.sh')
md5sums=('3b07850a9bc1ebfb921d31e10dabeb0f'
         '060cc93d6e9667030c3ad06e7fce9a3c')
conflicts=('backup')
backup=('etc/backup.conf')

package() {
	cd ${srcdir}
    install -Dm 644 ${_realname}.conf "${pkgdir}/etc/${_realname}.conf"
	install -Dm 755 ${_realname}.sh "${pkgdir}/usr/bin/${_realname}"
}
