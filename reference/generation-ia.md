# Génération par IA

À lire avant de générer une image, une vidéo, un modèle 3D ou un son, et pendant la phase d'identité visuelle. Le hook `garde-generation-ia` le rappelle.

Une image, une vidéo, un modèle 3D ou un son généré par IA est bien meilleur quand on parle au modèle comme son éditeur le conseille. Chaque modèle a sa façon : phrases ou mots-clés, prompt négatif compris ou ignoré, rôle des images de référence. Les modèles changent tous les quelques mois, et certains disparaissent.

## Avant de générer

- Lire la fiche du modèle dans `docs/generation-ia/modeles/`. Si elle manque ou a plus de 60 jours, se renseigner (recherche web, puis lecture des pages), puis écrire la fiche d'après `_modele.md`, avec ses sources et la date. Le hook `garde-generation-ia` refuse la génération sinon.
  - D'abord les guides officiels de l'éditeur. Beaucoup de docs ont un `llms.txt`.
  - Puis les guides de la communauté : le subreddit du modèle, son Discord, les tutoriels de créateurs reconnus. Ils ont souvent les meilleures astuces, que la doc ne donne pas.
  - Chaque astuce de la communauté entre dans la fiche avec sa source, et son résultat une fois essayée sur le projet. En cas de désaccord, la doc officielle fait foi jusqu'à ce qu'un essai donne raison à la communauté.
- Tout contenu destiné au produit part de la bible de style `docs/generation-ia/style.md`. Elle est écrite avec l'utilisateur pendant la phase d'identité visuelle, avant la première génération pour le produit. Les essais d'exploration peuvent la précéder.
- Estimer le coût quand l'outil le permet, et le dire à l'utilisateur avant une série.

## Écrire le prompt

- Décrire ce qu'on voit, le sujet d'abord, puis l'action, le lieu, la composition, la lumière et le style. Pas de mots creux comme « masterpiece » ou « 8k ».
- Formuler en positif : plusieurs modèles ignorent les prompts négatifs. « Fond uni gris » plutôt que « sans décor ».
- Le texte à afficher entre guillemets, avec sa police et sa position, puis relu sur l'image.
- Les couleurs en hexadécimal, rattachées à un objet.
- Court d'abord, un changement à la fois. Les brouillons en basse qualité, la version finale en haute.
- Pour retoucher : « ne change que X, garde tout le reste ».
- Aucun nom d'artiste, de marque ou de personnage protégé.
- Le prompt qui a marché, avec ses réglages et sa graine, va dans la fiche du modèle.

## Des contenus cohérents, dans l'ordre

1. La bible de style : palette en hexadécimal, lumière, matières, cadrage, ce qu'on évite, et un bloc de style commun ajouté à chaque prompt. Le sujet varie, le style non.
2. Trois à cinq images ancres validées par l'utilisateur, passées en références à chaque génération, avec le rôle de chacune (style, personnage, décor). Le nombre de références admis dépend du modèle.
3. En gros volume, un style entraîné : un LoRA sur 20 à 40 images légendées, ou le style entraîné d'un service (Scenario, Recraft, Krea).
4. Une graine fixe aide à comparer deux prompts, mais ne remplace ni les références ni un style entraîné.
5. Pour un personnage : une planche (face, profil, dos, pose en A ou en T, fond neutre), puis le modèle 3D à partir de plusieurs vues.
6. Pour une texture : « seamless tileable », vue de dessus, lumière diffuse, et le raccord vérifié dans le moteur.
7. Pour des icônes ou une interface : du vectoriel (SVG) ou un fond transparent, avec la palette imposée.
8. Toujours finir à la main : détourage, agrandissement, retouche, puis un essai en situation, dans le produit.

## Outils, par besoin

État au 25/10/2026 ; la fiche du modèle fait foi.

| Besoin | Point de départ | Guide officiel |
|---|---|---|
| Image et retouche par instructions | GPT Image, Nano Banana (Gemini), FLUX | [OpenAI](https://developers.openai.com/cookbook/examples/multimodal/image-gen-models-prompting-guide), [Google](https://ai.google.dev/gemini-api/docs/image-generation), [Black Forest Labs](https://docs.bfl.ai/guides/prompting_guide_flux2) |
| Texte dans l'image, logo | Ideogram | [Ideogram](https://docs.ideogram.ai/prompting/prompting.md) |
| Vectoriel, icônes, interface | Recraft | [Recraft](https://www.recraft.ai/docs/api-reference/models/recraft-v4) |
| Recherche de direction artistique | Midjourney (références de style, moodboards) | [Midjourney](https://updates.midjourney.com/) |
| Vidéo | Kling, Veo (Gemini), Seedance, Hailuo, Runway | [Kling](https://kling.ai/quickstart/klingai-video-3-model-user-guide), [Google](https://ai.google.dev/gemini-api/docs/video), [MiniMax](https://platform.minimax.io/docs/guides/video-generation), [Runway](https://docs.dev.runwayml.com/guides/models/) |
| Modèle 3D | Meshy, Tripo, Rodin ; Hunyuan3D en local, licence restreinte | [Meshy](https://docs.meshy.ai/en/webapp/text-to-3d), [Tripo par Scenario](https://help.scenario.com/articles/4692888910-tripo-family-the-complete-guide) |
| Voix, bruitages | ElevenLabs | [voix](https://elevenlabs.io/docs/overview/capabilities/text-to-speech/best-practices), [bruitages](https://elevenlabs.io/docs/overview/capabilities/sound-effects) |
| Musique | Suno, Lyria (Gemini) | [Suno](https://help.suno.com/en/articles/13924481), [Google](https://ai.google.dev/gemini-api/docs/interactions/music-generation) |
| Un style maison en volume | Scenario, Krea, ComfyUI en local | [Scenario](https://docs.scenario.com/), [Krea](https://www.krea.ai/docs/), [ComfyUI](https://docs.comfy.org/) |

## Droits

- Chaque contenu généré destiné au produit reçoit l'avertissement renforcé « ⚠⚠ Contenu généré par IA » de `securite-et-droits.md` : la déclaration aux boutiques, les droits de la formule, la protection, la trace.
- Les droits changent d'un modèle et d'une formule d'abonnement à l'autre : usage commercial, crédit obligatoire, territoires, seuils de revenus. La fiche du modèle les note. Au 25/10/2026, par exemple : les formules gratuites d'ElevenLabs et de Suno sont non commerciales, celle de Meshy oblige à créditer (CC BY 4.0), et la licence de Hunyuan3D 2.1 exclut l'Union européenne, le Royaume-Uni et la Corée du Sud.
