# **************************************************************************** #
#                                                                              #
#                                                         .--.    No           #
#    config-PATH.sh                                      |o_o |    Pain        #
#                                                        |:_/ |     No         #
#    By: YohanGH <YohanGH@proton.me>                    //    ''     Code      #
#                                                      (|     | )              #
#    Created: 2024/02/12 11:18:29 by YohanGH           '__   _/_               #
#    Updated: 2024/02/12 11:21:07 by YohanGH          (___)=(___)              #
#                                                                              #
# **************************************************************************** #

#!/usr/bin/env bash
#
echo "----------------------------------------------- /n"
echo "Début de la configuration de PATH..."
echo "----------------------------------------------- /n"


# Fonction pour afficher un message de début d'opération
start_operation() {
    echo -e "\n[INFO] Début de l'opération : $1..."
}

# Fonction pour afficher un message de fin d'opération
end_operation() {
    echo "[INFO] Fin de l'opération : $1."


# Configuration de la variable PATH pour inclure /usr/local/bin
start_operation "Configuration de la variable PATH"

# Détermine le fichier de configuration du shell à modifier en fonction du shell utilisé
SHELL_CONFIG_FILE="$HOME/.bash_profile"
[ -n "$ZSH_VERSION" ] && SHELL_CONFIG_FILE="$HOME/.zshrc"
[ -n "$BASH_VERSION" ] && SHELL_CONFIG_FILE="$HOME/.bash_profile"

echo "Modification de ${SHELL_CONFIG_FILE} pour inclure /usr/local/bin dans PATH..."

# Vérifie si /usr/local/bin est déjà dans PATH
if grep -q "/usr/local/bin" "$SHELL_CONFIG_FILE"; then
    echo "/usr/local/bin est déjà configuré dans PATH."
else
    # Ajoute /usr/local/bin à PATH dans le fichier de configuration du shell
    echo 'export PATH="/usr/local/bin:$PATH"' >> "$SHELL_CONFIG_FILE"
    echo "Configuration de PATH ajoutée à ${SHELL_CONFIG_FILE}."
fi

end_operation "Configuration de la variable PATH"



echo "\nConfiguration terminée avec succès."
echo "IMPORTANT : Pour appliquer les modifications, veuillez exécuter la commande suivante :"
echo "  source ${SHELL_CONFIG_FILE}"
echo "Appuyez sur [Enter] pour ouvrir un nouveau terminal dans lequel vous pourrez exécuter cette commande, ou fermez ce terminal et ouvrez-en un nouveau manuellement."
