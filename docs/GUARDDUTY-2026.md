# Essai des règles GuardDuty
Le capteur transmet les findings GuardDuty à partir de 7. Les règles optionnelles AWS sont un paramétrage de GuardDuty lui-même. Le mode DRY_RUN mesure les correspondances dans CloudWatch pendant au plus 14 jours. Il ne produit pas de finding à transmettre au bus. Fixer avant l’essai le compte, la région, le propriétaire, le coût accepté et le signal attendu.

Avec un détecteur existant dans le pilote et une version d’AWS CLI proposant ces opérations, inventorier puis choisir une règle selon le workload.

~~~bash
aws guardduty list-custom-detection-rules --profile pilot --region eu-west-1
aws guardduty list-custom-detection-rule-associations --profile pilot --region eu-west-1
~~~

Si aucune association ne gère déjà cette règle, lancer le pilote en utilisant son ID réel.

~~~bash
aws guardduty create-custom-detection-rule-association --rule-id "$RULE_ID" --mode DRY_RUN --profile pilot --region eu-west-1
~~~

Conserver l’ID d’association, la période, les métriques et le bruit observé. Au terme de l’essai, décider de laisser expirer, de retirer l’association ou de passer explicitement en LIVE. Si un administrateur délégué gère déjà les règles, réaliser l’essai depuis ce point d’administration. Vérifier les tarifs et la disponibilité régionale avant de choisir les profils Workloads ou IA. Pour Runtime Monitoring, vérifier la couverture des agents EC2/EKS/ECS. L’activation du plan ne prouve pas que les agents fonctionnent.

Sources AWS : [Custom Detection Rules](https://docs.aws.amazon.com/guardduty/latest/ug/custom-detection-rules.html), [association DRY_RUN](https://docs.aws.amazon.com/cli/latest/reference/guardduty/create-custom-detection-rule-association.html), [features du détecteur](https://docs.aws.amazon.com/guardduty/latest/APIReference/API_DetectorFeatureConfiguration.html).
