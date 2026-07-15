#!/bin/bash
# check-iso.sh - Vérifie si une image ISO est bootable, en distinguant
#   - le boot USB (MBR hybrid-boot / table de partitions + partition EFI)
#   - le boot CD/DVD (El Torito, avec détail BIOS/UEFI)
# Usage: ./check-iso.sh <image.iso>
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ $# -eq 0 ]; then
    echo "Usage: $0 <image.iso>"
    exit 1
fi

IMAGE_ISO="$1"
if [ ! -f "$IMAGE_ISO" ]; then
    echo -e "${RED}Erreur: Le fichier '$IMAGE_ISO' n'existe pas${NC}"
    exit 1
fi

# Vérification des dépendances
for cmd in file hexdump fdisk isoinfo xorriso; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo -e "${YELLOW}Attention: '$cmd' n'est pas installé, certains tests seront ignorés${NC}"
    fi
done

echo "=========================================="
echo "Analyse de: $(basename "$IMAGE_ISO")"
echo "=========================================="
echo

# ---------------------------------------------------------
# Test 1: Type de fichier
# ---------------------------------------------------------
echo -e "${YELLOW}[1/6] Type de fichier${NC}"
FILE_OUTPUT=$(file "$IMAGE_ISO")
echo "$FILE_OUTPUT"
if echo "$FILE_OUTPUT" | grep -q "bootable"; then
    echo -e "${GREEN}✓ Marquée 'bootable' par file(1)${NC}"
    FILE_BOOTABLE_OK=1
else
    echo -e "${RED}✗ Non marquée 'bootable' par file(1)${NC}"
    echo -e "${RED}  Signal fort : file(1) n'a pas reconnu de code de bootstrap valide dans les 440${NC}"
    echo -e "${RED}  premiers octets. Un cas réel (AnduinOS, juillet 2026) a montré que c'était${NC}"
    echo -e "${RED}  la seule différence entre une ISO qui ne bootait ni en VirtualBox ni sur 2 PC${NC}"
    echo -e "${RED}  physiques, et sa version reconstruite qui bootait partout. Signature MBR et${NC}"
    echo -e "${RED}  table de partitions présentes n'ont pas suffi dans ce cas — traiter ce signal${NC}"
    echo -e "${RED}  comme un vrai problème probable, pas comme un simple avertissement mineur${NC}"
    FILE_BOOTABLE_OK=0
fi
echo

# ---------------------------------------------------------
# Test 2: Signature MBR (55 aa à l'offset 510-511)
# ---------------------------------------------------------
echo -e "${YELLOW}[2/6] Signature MBR (boot USB Legacy)${NC}"
MBR_SIG=$(hexdump -C -s 510 -n 2 "$IMAGE_ISO" | awk '{print $2, $3}')
echo "Signature trouvée: $MBR_SIG"
MBR_OK=0
if echo "$MBR_SIG" | grep -q "55 aa"; then
    echo -e "${GREEN}✓ Signature MBR valide${NC}"
    MBR_OK=1
else
    echo -e "${RED}✗ Signature MBR absente ou invalide${NC}"
fi
echo

# ---------------------------------------------------------
# Test 3: Table de partitions + partition EFI
# ---------------------------------------------------------
echo -e "${YELLOW}[3/6] Table de partitions (boot USB Legacy + UEFI)${NC}"
FDISK_OUTPUT=$(LC_ALL=C fdisk -l "$IMAGE_ISO" 2>/dev/null || true)
PART_OK=0
EFI_PART_OK=0
if echo "$FDISK_OUTPUT" | grep -q "Disklabel type"; then
    echo "$FDISK_OUTPUT" | grep -E "Disklabel type|Device|Boot|Start|End|Sectors|Size|Type|^${IMAGE_ISO}"
    echo -e "${GREEN}✓ Table de partitions présente${NC}"
    PART_OK=1
    if echo "$FDISK_OUTPUT" | grep -qi "EFI"; then
        echo -e "${GREEN}✓ Partition EFI détectée (boot UEFI depuis clé USB probable)${NC}"
        EFI_PART_OK=1
    else
        echo -e "${YELLOW}~ Aucune partition EFI dans la table (UEFI via USB incertain)${NC}"
    fi
    # Alerte type de partition incohérent : une zone hybrid-boot ne devrait
    # jamais être typée "Linux" (0x83) - signal vu sur l'ISO AnduinOS d'origine,
    # qui n'a jamais réussi à booter (cf. échange du 2026-07-06)
    if echo "$FDISK_OUTPUT" | grep -E "^${IMAGE_ISO}1" | grep -qi "Linux"; then
        echo -e "${YELLOW}⚠ Partition 1 typée 'Linux' : incohérent pour une zone ISO9660 hybrid-boot,${NC}"
        echo -e "${YELLOW}  signal déjà observé sur une ISO qui ne bootait pas (cf. cas AnduinOS)${NC}"
    fi
else
    echo -e "${RED}✗ Aucune table de partitions détectée${NC}"
fi
echo

# ---------------------------------------------------------
# Test 4: El Torito détaillé (boot CD/DVD physique ou virtuel)
# ---------------------------------------------------------
echo -e "${YELLOW}[4/6] El Torito (boot CD/DVD, physique ou virtuel)${NC}"
ELTORITO_BIOS=0
ELTORITO_UEFI=0
if command -v xorriso >/dev/null 2>&1; then
    XORRISO_OUT=$(xorriso -indev "$IMAGE_ISO" -report_el_torito plain 2>/dev/null || true)
    if [ -n "$XORRISO_OUT" ]; then
        echo "$XORRISO_OUT"
        if echo "$XORRISO_OUT" | grep -qi "BIOS"; then
            ELTORITO_BIOS=1
        fi
        if echo "$XORRISO_OUT" | grep -qi "UEFI\|EFI"; then
            ELTORITO_UEFI=1
        fi
    fi
fi
# Repli sur isoinfo si xorriso absent ou muet
if [ "$ELTORITO_BIOS" -eq 0 ] && [ "$ELTORITO_UEFI" -eq 0 ] && command -v isoinfo >/dev/null 2>&1; then
    ISOINFO_ELTORITO=$(isoinfo -d -i "$IMAGE_ISO" 2>/dev/null | grep -i "El Torito" || true)
    if [ -n "$ISOINFO_ELTORITO" ]; then
        echo "$ISOINFO_ELTORITO"
        echo -e "${YELLOW}~ Catalogue El Torito présent, mais impossible de distinguer BIOS/UEFI sans xorriso${NC}"
        ELTORITO_BIOS=1  # présence confirmée, granularité inconnue
    fi
fi

if [ "$ELTORITO_BIOS" -eq 1 ] && [ "$ELTORITO_UEFI" -eq 1 ]; then
    echo -e "${GREEN}✓ El Torito BIOS + UEFI : boot CD/DVD complet${NC}"
elif [ "$ELTORITO_BIOS" -eq 1 ]; then
    echo -e "${YELLOW}~ El Torito présent (BIOS uniquement, ou granularité non déterminée)${NC}"
else
    echo -e "${RED}✗ El Torito absent : pas de boot CD/DVD ni de boot via ISO monté en virtuel (ex: qemu -cdrom)${NC}"
fi
echo

# ---------------------------------------------------------
# Test 5: Fichiers EFI réels dans l'arborescence (contrôle croisé)
# ---------------------------------------------------------
echo -e "${YELLOW}[5/6] Présence de fichiers .efi dans l'ISO (contrôle croisé UEFI)${NC}"
EFI_FILES_OK=0
if command -v isoinfo >/dev/null 2>&1; then
    EFI_LIST=$(isoinfo -R -f -i "$IMAGE_ISO" 2>/dev/null | grep -i '\.efi$' || true)
    if [ -n "$EFI_LIST" ]; then
        echo "$EFI_LIST"
        echo -e "${GREEN}✓ Fichier(s) .efi trouvé(s) dans l'arborescence${NC}"
        EFI_FILES_OK=1
    else
        echo -e "${RED}✗ Aucun fichier .efi trouvé dans l'arborescence${NC}"
    fi
fi
echo

# ---------------------------------------------------------
# Test 6: Couverture de la table de partitions vs taille réelle du fichier
# ---------------------------------------------------------
# Sur l'ISO AnduinOS d'origine (qui ne bootait pas), la dernière partition
# déclarée (EFI) se terminait ~74,7 Mio avant la fin réelle du fichier.
# Un tel écart suggère une table de partitions calculée sur une taille
# antérieure à la taille finale (reliquat de pipeline de build).
# Sur la version reconstruite (fonctionnelle), l'écart n'était que de
# ~300 Kio, une simple marge d'alignement normale.
echo -e "${YELLOW}[6/6] Couverture de la table de partitions${NC}"
COVERAGE_OK=1
if [ "$PART_OK" -eq 1 ] && command -v stat >/dev/null 2>&1; then
    FILE_SIZE_BYTES=$(stat -c%s "$IMAGE_ISO" 2>/dev/null || echo 0)
    if [ "$FILE_SIZE_BYTES" -gt 0 ]; then
        TOTAL_SECTORS=$((FILE_SIZE_BYTES / 512))
        LAST_PART_END=$(LC_ALL=C fdisk -l -o End "$IMAGE_ISO" 2>/dev/null | grep -E '^[0-9]+$' | sort -n | tail -1 || true)
        if [ -n "${LAST_PART_END:-}" ]; then
            GAP_SECTORS=$((TOTAL_SECTORS - LAST_PART_END))
            GAP_MIB=$((GAP_SECTORS * 512 / 1024 / 1024))
            echo "Taille totale: $TOTAL_SECTORS secteurs | Fin dernière partition: $LAST_PART_END | Écart: $GAP_SECTORS secteurs (~${GAP_MIB} Mio)"
            # seuil: au-delà de ~2000 secteurs (~1 Mio), ce n'est plus une simple marge d'alignement
            if [ "$GAP_SECTORS" -gt 2000 ]; then
                echo -e "${RED}✗ Écart important non couvert par la table de partitions (~${GAP_MIB} Mio)${NC}"
                echo -e "${RED}  Signal similaire à une ISO qui ne bootait pas (cf. cas AnduinOS) — des fichiers${NC}"
                echo -e "${RED}  de boot pourraient se trouver hors de la zone déclarée${NC}"
                COVERAGE_OK=0
            else
                echo -e "${GREEN}✓ Écart négligeable, cohérent avec une marge d'alignement normale${NC}"
            fi
        else
            echo -e "${YELLOW}~ Impossible de déterminer la fin de la dernière partition${NC}"
        fi
    else
        echo -e "${YELLOW}~ Taille de fichier non déterminée, test ignoré${NC}"
    fi
else
    echo -e "${YELLOW}~ Test ignoré (pas de table de partitions ou 'stat' indisponible)${NC}"
fi
echo

# ---------------------------------------------------------
# Résumé final - deux cibles séparées
# ---------------------------------------------------------
echo "=========================================="
echo "RÉSUMÉ"
echo "=========================================="

echo -e "${YELLOW}--- Boot depuis clé USB (dd / Etcher / Gnome Disks) ---${NC}"
USB_SCORE=$((MBR_OK + PART_OK + EFI_PART_OK + EFI_FILES_OK))
if [ "$COVERAGE_OK" -eq 0 ] || [ "$FILE_BOOTABLE_OK" -eq 0 ]; then
    echo -e "${RED}✗ USB à risque élevé malgré signature MBR/table de partitions présentes${NC}"
    if [ "$FILE_BOOTABLE_OK" -eq 0 ]; then
        echo -e "${RED}  → file(1) ne reconnaît pas de code de bootstrap valide (test 1)${NC}"
    fi
    if [ "$COVERAGE_OK" -eq 0 ]; then
        echo -e "${RED}  → la table de partitions ne couvre pas tout le contenu réel (test 6)${NC}"
    fi
    echo -e "${RED}  Ces deux signaux se sont avérés déterminants sur un cas réel qui ne bootait pas${NC}"
elif [ "$USB_SCORE" -ge 3 ]; then
    echo -e "${GREEN}✓ USB Legacy BIOS + UEFI : devrait booter largement (PC anciens et récents)${NC}"
elif [ "$USB_SCORE" -ge 1 ]; then
    echo -e "${YELLOW}⚠ USB partiellement fiable ($USB_SCORE/4) : un des deux modes de boot peut échouer${NC}"
else
    echo -e "${RED}✗ USB non bootable${NC}"
fi

echo
echo -e "${YELLOW}--- Boot depuis CD/DVD (gravure physique ou montage virtuel) ---${NC}"
if [ "$ELTORITO_BIOS" -eq 1 ] && [ "$ELTORITO_UEFI" -eq 1 ]; then
    echo -e "${GREEN}✓ CD/DVD bootable en BIOS et UEFI${NC}"
elif [ "$ELTORITO_BIOS" -eq 1 ]; then
    echo -e "${YELLOW}⚠ CD/DVD probablement bootable en BIOS Legacy uniquement${NC}"
else
    echo -e "${RED}✗ CD/DVD non bootable (pas de El Torito) — clé USB uniquement${NC}"
fi
echo "=========================================="
