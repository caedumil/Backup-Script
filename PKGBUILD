# Maintainer: Caedus <caedus75@gmail.com>

pkgname=script-backup
_realname=backup
pkgver=13.0
pkgrel=1
pkgdesc="Script para backup dos meu arquivos pessoais"
arch=('any')
license=('GPL3')
depends=('rsync')
source=('backup.cfg' 'backup.sh')
md5sums=('7b8738912ca5a71392f3a59aba7dc438'
         'b78925ab353ce0fbe5d7fdeda7c2ff6e')
conflicts=('backup')
backup=('etc/backup.cfg')

package() {
	cd ${srcdir}
    install -Dm 644 ${_realname}.cfg "${pkgdir}/etc/${_realname}.cfg"
	install -Dm 755 ${_realname}.sh "${pkgdir}/usr/bin/${_realname}"
}
