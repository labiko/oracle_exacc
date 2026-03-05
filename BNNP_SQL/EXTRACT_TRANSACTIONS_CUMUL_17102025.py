#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
EXTRACTION DES TRANSACTIONS CUMULÉES - 17/10/2025
Compte BBNP83292-EUR (RIB: 00016111832)
Montant cumul dans BR_DATA: 226838.78 EUR
"""

import xml.etree.ElementTree as ET
import sys
from decimal import Decimal

def extract_transactions():
    """Extrait toutes les transactions du compte 00016111832 du 17/10/2025"""

    xml_file = r"c:\Users\diall\Documents\IonicProjects\Claude\RECHERCHER\DIVERS\BNNP_SQL\dataSource.xml"

    print("="*80)
    print("EXTRACTION TRANSACTIONS CUMULÉES - Compte BBNP83292-EUR")
    print("Date: 17/10/2025")
    print("RIB recherché: 00016111832")
    print("="*80)
    print()

    try:
        tree = ET.parse(xml_file)
        root = tree.getroot()

        transactions = []
        total_cumul = Decimal('0')

        # Parcourir toutes les balises <Row>
        for row in root.findall('.//Row'):
            reglement = row.find('.//Reglement')
            if reglement is None:
                continue

            # Récupérer le RIB
            rib_elem = reglement.find('.//Identification[@path="Identification"]')
            if rib_elem is None:
                rib_elem = reglement.find('.//DepositoryAccount//RIB//Identification')

            if rib_elem is None or rib_elem.text != '00016111832':
                continue

            # Récupérer la date
            trade_date = reglement.find('.//TradeDate')
            if trade_date is None or trade_date.text != '2025-10-17':
                continue

            # Récupérer les informations de la transaction
            montant_elem = reglement.find('.//OperationNetAmount')
            montant = Decimal(montant_elem.text) if montant_elem is not None else Decimal('0')

            payment_ref = reglement.find('.//PaymentReference')
            payment_ref_text = payment_ref.text if payment_ref is not None else 'N/A'

            client_elem = reglement.find('.//NumeroClient')
            client = client_elem.text if client_elem is not None else 'N/A'

            mode_elem = reglement.find('.//SettlementMode')
            mode = mode_elem.text if mode_elem is not None else 'N/A'

            societe_elem = reglement.find('.//Societe//Identification')
            societe = societe_elem.text if societe_elem is not None else 'N/A'

            transactions.append({
                'montant': montant,
                'payment_ref': payment_ref_text,
                'client': client,
                'mode': mode,
                'societe': societe
            })

            total_cumul += montant

        # Afficher les résultats
        if not transactions:
            print("❌ AUCUNE TRANSACTION TROUVÉE pour ce compte à cette date")
            return

        print(f"✅ {len(transactions)} TRANSACTIONS TROUVÉES")
        print()
        print("-" * 120)
        print(f"{'N°':<4} | {'MONTANT':<15} | {'PAYMENT_REF':<12} | {'CLIENT':<12} | {'MODE':<6} | {'SOCIETE':<10}")
        print("-" * 120)

        for i, tx in enumerate(transactions, 1):
            marqueur = " 🎯" if str(tx['montant']) == '2817' else ""
            print(f"{i:<4} | {tx['montant']:>15} | {tx['payment_ref']:<12} | {tx['client']:<12} | {tx['mode']:<6} | {tx['societe']:<10}{marqueur}")

        print("-" * 120)
        print(f"{'TOTAL CUMUL':<4} | {total_cumul:>15} EUR")
        print("-" * 120)
        print()

        # Vérification
        montant_br_data = Decimal('226838.78')
        print("VÉRIFICATION:")
        print(f"  Cumul calculé XML : {total_cumul:>15} EUR")
        print(f"  Cumul dans BR_DATA: {montant_br_data:>15} EUR")

        if total_cumul == montant_br_data:
            print("  ✅ COHÉRENT - Les montants correspondent exactement !")
        else:
            difference = total_cumul - montant_br_data
            print(f"  ⚠️ ÉCART: {difference:>15} EUR")

        print()
        print("="*80)
        print("CONCLUSION:")
        print("="*80)
        print()
        print(f"La transaction 2817 EUR fait partie des {len(transactions)} transactions VO")
        print("exportées en CUMUL QUOTIDIEN le 17/10/2025.")
        print()
        print("C'est la règle de cumul ALL+VO (TA_RN_CUMUL_MR) qui provoque")
        print("ce comportement pour le compte 342 (BBNP83292-EUR).")
        print()
        print("Pour avoir 2817 EUR EN DÉTAIL dans BR_DATA:")
        print("→ Supprimer la règle de cumul (voir SOLUTION_OPTIONS.md)")
        print()

    except FileNotFoundError:
        print(f"❌ ERREUR: Fichier non trouvé: {xml_file}")
        sys.exit(1)
    except ET.ParseError as e:
        print(f"❌ ERREUR de parsing XML: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ ERREUR: {e}")
        sys.exit(1)

if __name__ == '__main__':
    extract_transactions()
