# Maintainer: Caedus <caedus75@gmail.com>

pkgname=script-backup
_realname=backup
pkgver=2.1.0
pkgrel=1
pkgdesc="Script para backup dos meu arquivos pessoais"
arch=('any')
license=('GPL3')
depends=('rsync')
source=('backup.conf' 'backup.sh')
md5sums=('7b8738912ca5a71392f3a59aba7dc438'
         '1dac77500a035dd3b28571c37eec4425')
conflicts=('backup')
backup=('etc/backup.conf')

package() {
	cd ${srcdir}
    install -Dm 644 ${_realname}.conf "${pkgdir}/etc/${_realname}.conf"
	install -Dm 755 ${_realname}.sh "${pkgdir}/usr/bin/${_realname}"
}
