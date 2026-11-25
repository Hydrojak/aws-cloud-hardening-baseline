# AWS Cloud Hardening Baseline V3

Terraform pour séparer l’administration AWS Organizations, la conservation des journaux et la détection. Un signal IAM émis en Virginie peut ainsi parvenir au compte sécurité en Irlande. Les journaux originaux sont conservés dans un troisième compte. Le profil mono-compte garde son point d’entrée historique dans `terraform/`.

[Menace → contrôle → preuve de test](docs/MATRICE.md) · [Déploiement et recette](docs/EXPLOITATION.md) · [Résultats de cette livraison](docs/evidence/RESULTATS.md) · [Migration V2](docs/MIGRATION.md) · [Coûts](COST_GUARDRAILS.md)

| Compte | Point d’entrée | Responsabilité et limite |
|---|---|---|
| Management | `stacks/management` | Trail d’organisation multirégion, contrôle toutes les cinq minutes, topic de santé indépendant, budget optionnel et policies sur une OU pilote. Le rôle de contrôle en lecture seule est le réglage initial. |
| Log Archive | `stacks/archive` | Bucket CloudTrail versionné et chiffré avec clé KMS, blocage public, TLS, Object Lock Governance et expiration des versions. Le compte management ne reçoit aucun droit général de lecture des archives via la baseline. |
| Security Tooling | `stacks/security` | Bus EventBridge central, liste de comptes autorisés, règles par menace, logs, alarmes et file d’échec. Chaque transition vers ALARM peut notifier SNS. |
| Chaque compte surveillé | `stacks/member` | Un état par compte. Des règles sur le bus par défaut de chaque région transfèrent les événements retenus vers Security Tooling. Installer aussi dans Management, Archive et Security si leurs événements doivent être couverts. |
| Administrateur IAM Identity Center | `stacks/identity` | Affecte un groupe existant à une permission d’investigation de deux heures dans Security Tooling. L’IdP et sa politique MFA ont leur propre administration. |
| Chaque propriétaire d’état | `stacks/state` | Bootstrap d’un bucket de state privé et versionné, avec clé KMS et verrou S3 natif dans la configuration du backend. |

~~~mermaid
flowchart TD
    M["Management"] --> T["CloudTrail organisation"]
    T --> A["Log Archive · S3 et KMS"]
    M --> H["Contrôle de santé périodique"]
    H --> N["SNS de santé"]
    R["Bus régionaux des comptes"] --> B["Bus Security Tooling"]
    B --> L["Logs de détection"]
    B --> C["Alarmes puis SNS"]
    R --> D["Files d’échec régionales"]
    B --> Q["File d’échec centrale"]
~~~

**Démarrer par les tests.** Depuis la racine, Bash, Python 3.11+, Java 17+ avec son compilateur, Terraform 1.14.7. AWS 6.74.0 et Archive 2.8.1 sont verrouillés. Sous Windows, utiliser WSL. Le premier passage récupère les dépendances et vérifie leurs empreintes.

~~~bash
bash scripts/check.sh local
bash scripts/check.sh ci
~~~

Le premier parcours vérifie le format, la logique de remédiation, les événements et la politique de confiance. Le second initialise les sept racines sans backend, appelle `validate`, joue les plans avec providers simulés et exécute le scan IaC. La CI n’a besoin d’aucun identifiant AWS. Le résultat de la recette sur AWS doit être conservé séparément des tests simulés.

| Profil | Mise en service |
|---|---|
| Lab | Utiliser `examples/lab.tfvars.example` avec `terraform/`. Le second relais couvre par défaut `us-east-1` si la région principale est différente. L’email SNS doit être confirmé. Ce profil conserve les quatre familles d’alarmes historiques. |
| Organisation | Installer les stacks avec leurs états et identités séparés. Les exemples utilisent quatre comptes fictifs. Une nouvelle région ou un nouveau compte nécessite un changement d’inventaire et de capteurs. |
| Workloads | Superposer `examples/workloads.tfvars.example` au fichier membre dans les régions compatibles. Vérifier détecteur, agents et coûts avant activation. |
| IA | Superposer `examples/ai.tfvars.example` pour des workloads Bedrock/SageMaker compatibles. Pour combiner les deux profils, utiliser une seule liste `guardduty_features` contenant les deux valeurs. |

Le catalogue comprend neuf familles, dont le probe de livraison. Il distingue le format ASFF de Security Hub CSPM et le format OCSF de Security Hub V2. Les détecteurs déjà gérés par l’organisation peuvent alimenter les règles sans être recréés par Terraform. Le guide décrit également l’évaluation des règles GuardDuty en dry-run. [Évolutions AWS et pilote GuardDuty](docs/GUARDDUTY-2026.md)

Base de migration : commit `91bf177ab8df14abd9cb7e2d60557762a476f33a`. Les documents V2 sont conservés sous `docs/history/v2/`.
