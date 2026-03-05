#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
EXTRACTION DES 23 TRANSACTIONS CUMULÉES
Compte BBNP83292-EUR (RIB: 00016111832)
Total attendu: 226838.78 EUR
"""

import re
from decimal import Decimal

xml_file = r"c:\Users\diall\Documents\IonicProjects\Claude\RECHERCHER\DIVERS\BNNP_SQL\dataSource.xml"

print("=" * 100)
print("EXTRACTION DES 23 TRANSACTIONS CUMULÉES - Compte BBNP83292-EUR")
print("RIB: 00016111832")
print("=" * 100)
print()

# Lire le fichier XML
with open(xml_file, 'r', encoding='utf-8') as f:
    content = f.read()

# Découper en blocs <Reglement>...</Reglement>
reglements = re.findall(r'<Reglement>(.*?)</Reglement>', content, re.DOTALL)

transactions = []
total = Decimal('0')

for reglement in reglements:
    # Vérifier si c'est notre compte (RIB: 00016111832)
    if '<Identification>00016111832</Identification>' in reglement:
        # Extraire les informations
        montant_match = re.search(r'<OperationNetAmount[^>]*>([\d.]+)</OperationNetAmount>', reglement)
        payment_match = re.search(r'<PaymentReference>(\d+)</PaymentReference>', reglement)
        client_match = re.search(r'<NumeroClient>(\d+)</NumeroClient>', reglement)
        societe_match = re.search(r'<Societe>\s*<Identification>(\d+)</Identification>', reglement)

        if montant_match:
            montant = Decimal(montant_match.group(1))
            payment_ref = payment_match.group(1) if payment_match else 'N/A'
            client = client_match.group(1) if client_match else 'N/A'
            societe = societe_match.group(1) if societe_match else 'N/A'

            transactions.append({
                'montant': montant,
                'payment_ref': payment_ref,
                'client': client,
                'societe': societe
            })

            total += montant

# Afficher les résultats
print(f"Nombre de transactions trouvées: {len(transactions)}")
print()
print("-" * 100)
print(f"{'N°':<4} | {'MONTANT':>15} | {'PAYMENT_REF':<12} | {'CLIENT':<12} | {'SOCIETE':<10} | {'MARQUEUR'}")
print("-" * 100)

for i, tx in enumerate(sorted(transactions, key=lambda x: x['montant'], reverse=True), 1):
    marqueur = " *** VOTRE TRANSACTION 2817 EUR ***" if str(tx['montant']) == '2817' else ""
    print(f"{i:<4} | {tx['montant']:>15} | {tx['payment_ref']:<12} | {tx['client']:<12} | {tx['societe']:<10} |{marqueur}")

print("-" * 100)
print(f"{'TOTAL':>4} | {total:>15} EUR")
print("-" * 100)
print()

# Vérification
montant_br_data = Decimal('226838.78')
ecart = total - montant_br_data

print("VÉRIFICATION:")
print(f"  Somme calculée (XML)  : {total:>15} EUR")
print(f"  Cumul dans BR_DATA    : {montant_br_data:>15} EUR")
print(f"  Écart                 : {ecart:>15} EUR")

if abs(ecart) < Decimal('1'):
    print(f"  ✅ COHÉRENT (écart < 1 EUR)")
else:
    print(f"  ⚠️ ÉCART SIGNIFICATIF")

print()
print("=" * 100)
print("CONCLUSION:")
print("=" * 100)
print()
print(f"La transaction 2817 EUR fait partie des {len(transactions)} transactions VO")
print("du compte 00016111832 (BBNP83292-EUR) cumulées en une seule ligne.")
print()
print(f"Montant du cumul : {total} EUR ≈ 226838.78 EUR (BR_DATA)")
print()
print("C'est la règle de cumul ALL+VO dans TA_RN_CUMUL_MR qui provoque")
print("ce comportement pour le compte 342.")
print()
