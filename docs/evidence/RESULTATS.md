# Résultats de livraison V3

| Vérification | Résultat du 25 novembre 2026 |
|---|---|
| Source | L’archive et le HEAD public de `main` observé au début de la réalisation avaient le même SHA, `91bf177ab8df14abd9cb7e2d60557762a476f33a`. |
| Terraform | CLI 1.14.7, AWS 6.74.0, Archive 2.8.1. Initialisation locale sans backend des sept racines, et vérification du format récursif réussies. |
| Logique Python | 17 tests réussis. 14 portent sur la Lambda et 3 sur le verdict de la sonde de livraison avec des réponses AWS simulées. |
| Détections | 21 fixtures positives et négatives passées au moteur open source AWS Event Ruler 1.8.2 avec le catalogue livré. |
| Politiques du bus et de l’archive | 7 tests Terraform natifs réussis sur les deux modules de policies sans provider externe. Trois portent sur la confiance du bus et quatre sur le principal de livraison, la provenance, les préfixes et le refus HTTP de l’archive. |
| Scan IaC | Trivy 0.76.2 avec règles embarquées. [Résultats et interprétation](scan.json). Un constat HIGH, sept LOW, zéro CRITICAL sur cette configuration analysée. |
| Validation des sept racines avec schémas des providers et douze scénarios Terraform simulés | À confirmer sur la CI livrée. La création de socket Unix pour le dialogue Terraform/provider est refusée dans l’environnement de réalisation. L’initialisation a réussi, mais elle ne remplace pas `terraform validate`. |
| AWS réel | Aucun `apply` effectué. Les tests AWS CLI, la livraison SNS vers une boîte confirmée, la restauration d’une version réelle et la vérification de signature restent à exécuter dans l’OU pilote. Aucun résultat AWS réel n’a été prérempli. |

Le scan cible le code avec les valeurs disponibles et ses règles embarquées. Le HIGH AWS-0132 concerne l’entrée lab avec SSE-S3. Pour un lab imposant une CMK, fournir `cloudtrail_kms_key_arn`. L’archive d’organisation emploie une CMK par défaut. `scripts/scan.py` bloque tout nouveau constat HIGH/CRITICAL hors de cette exception précise.

Les sept occurrences LOW concernent l’absence de server access logging sur certains buckets, l’absence de copie intégrale de CloudTrail vers CloudWatch Logs, la clé du groupe de logs de la Lambda et l’absence de tracing X-Ray. La V3 conserve les originaux CloudTrail dans S3 et envoie les détections sélectionnées vers CloudWatch. Comparer le volume et les exigences de conservation avant d’ajouter une seconde copie de tout le trail. Le log de la Lambda sert à sa santé et ne réplique pas les événements bruts.

[Sortie des tests exécutés](local-tests.txt) · [Matrice de preuve](../MATRICE.md) · [Recette AWS](../EXPLOITATION.md).
