# weblogic

deploying an Oracle WebLogic Server application Two-cluster architecture and administrative server using terraform and Ansible

## Подготовка к установке для развёртывания инфраструктуры

Компания Hashicorp <https://www.hashicorp.com/> поставляет на рынок opensource решения, направленые на решение задач управления инфраструктурой.

- Vault - позволяет управлять секретами.
- Terraform - позволяет создавать и отслеживать инфраструктуру.Отличительной особенностью является наличие файла блокирующего одновременное изменение инфраструктуры несколькими пользователями.

Terraform представляет мобой модульное решение, позволяющее использовать различные облачные решения <https://www.terraform.io/docs/providers/index.html>. </br>
Для исользования Qemu виртуализации, требуется описать провайдер или использовать <https://github.com/dmacvicar/terraform-provider-libvirt>

### Использование terraform

- Определить переменные
  - "ANSIBLE_USER" - имя пользователя
  - "SSH_KEY_PATH" - публичный ключ
  - "LIBVIRT_POOL_DIR" - каталог хранения VM
  - "RH81_IMG_URL_64" - полный путь к файлу rhel-8.1-x86_64-kvm.
    qcow2 или другому образу системы эксперименты с Oracle-linux и ubuntu проблем не выявили
  - "COUNT_VM" количество однотипный виртуальных машин
- в каталоге terraform выполнить команду terraform init, которая создаст каталог .terraform
- развертывание инфраструктуры - команда terraform apply
- удаление инфрастуктуры - команда terraform destroy

#### Примечание

Пользуйтесь приведённыи командами, так как при ручном удалении остаются артефакты, которые мешают повторному использованию кода. В частности невимый в менеджере виртуальных машин virsh net-list --all (weblogic_network inactive no yes) и видимый virsh pool-list (weblogic_env active yes).
Вызывают ошибки:

- Error: Error defining libvirt network: virError(Code=9, Domain=19, Message='operation failed: network 'weblogic_network' already exists with uuid
- Error: storage pool 'weblogic_env' already exists
