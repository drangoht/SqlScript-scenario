# Paramètres
$repoGit = "C:\chemin\vers\votre\repo.git" # Remplacez par le chemin réel
$commitDebut = "hash_du_commit_debut" # Remplacez par le hash du commit de début
$commitFin = "hash_du_commit_fin" # Remplacez par le hash du commit de fin
$serveurSQL = "nom_du_serveur"
$baseDeDonnees = "nom_de_la_base"

# Fonction pour analyser les dépendances d'un fichier SQL
function Get-DependancesSQL {
    param(
        [string]$fichier
    )

    $contenu = Get-Content $fichier -Raw
    $dependances = @()

    # Expressions régulières (à adapter)
    $regexObjets = "(CREATE (TABLE|VIEW|FUNCTION|PROCEDURE)|ALTER (TABLE|VIEW|FUNCTION|PROCEDURE)|(INSERT|UPDATE|DELETE) INTO|EXEC|CALL) ([dbo\.]*)(\w+)"

    # Analyse des dépendances à l'extérieur de l'objet
    [regex]::Matches($contenu, $regexObjets) | ForEach-Object {
        $dependances += $_.Groups[4].Value
    }

    # Analyse à l'intérieur des procédures et fonctions
    if ($contenu -match "CREATE (PROCEDURE|FUNCTION)") {
        $corpsObjet = $contenu -replace "(?smi).*AS\s+(.*?)\s+GO.*", '$1' # Extraction du corps
        [regex]::Matches($corpsObjet, $regexObjets) | ForEach-Object {
            $dependances += $_.Groups[4].Value
        }
    }

    return $dependances | Sort-Object -Unique
}

# Récupérer la liste des commits entre les deux commits spécifiés
$commits = git log --pretty=format:"%H" $commitDebut..$commitFin

# Tableau pour stocker les fichiers temporaires
$fichiersTemporaires = @()
$dependances = @{} # Initialisation du tableau des dépendances

# Traiter chaque commit
foreach ($commit in $commits) {
    Write-Host "Traitement du commit : $commit"

    # Récupérer les fichiers SQL modifiés ou ajoutés dans ce commit
    $fichiersSQLGit = git diff-tree --name-only $commit^ $commit | Where-Object { $_ -match "\.sql$" }

    # Traiter chaque fichier SQL
    foreach ($fichierGit in $fichiersSQLGit) {
        # Extraire le contenu du fichier depuis Git
        $contenuSQL = git show $commit:$fichierGit

        # Créer un fichier temporaire
        $fichierTemp = [System.IO.Path]::GetTempFileName() + ".sql"
        Set-Content -Path $fichierTemp -Value $contenuSQL -Encoding UTF8 # Encodage UTF8

        # Ajouter le fichier temporaire au tableau
        $fichiersTemporaires += $fichierTemp

        # Construire le graphe de dépendances
        $nomScript = [System.IO.Path]::GetFileNameWithoutExtension($fichierGit)
        $dependances[$nomScript] = Get-DependancesSQL -fichier $fichierTemp
    }
}

# Tri topologique (algorithme de Kahn)
$listeScriptsOrdonnes = @() # L (Liste ordonnée des scripts)
$ensembleScriptsSansDependances = $dependances.Where({ $_.Value -eq $null -or $_.Value.Count -eq 0 }).Keys # S (Ensemble des scripts sans dépendances)

while ($ensembleScriptsSansDependances) {
    $scriptCourant = $ensembleScriptsSansDependances[0] # n (Script courant)
    $ensembleScriptsSansDependances = $ensembleScriptsSansDependances[1..($ensembleScriptsSansDependances.Count - 1)]
    $listeScriptsOrdonnes += $scriptCourant
    foreach ($script in $dependances.Keys) { # m (Script dans le graphe)
        if ($dependances[$script] -contains $scriptCourant) {
            $dependances[$script] = $dependances[$script] | Where-Object { $_ -ne $scriptCourant }
            if ($dependances[$script] -eq $null -or $dependances[$script].Count -eq 0) {
                $ensembleScriptsSansDependances += $script
            }
        }
    }
}

# Exécuter les scripts SQL dans l'ordre
foreach ($script in $listeScriptsOrdonnes) {
    $cheminScript = $fichiersTemporaires | Where-Object { [System.IO.Path]::GetFileNameWithoutExtension($_) -eq $script }
    Write-Host "Exécution du script : $cheminScript"
    try {
        Invoke-Sqlcmd -ServerInstance $serveurSQL -Database $baseDeDonnees -InputFile $cheminScript
    }
    catch {
        Write-Error "Erreur lors de l'exécution de $cheminScript : $_"
        # Gestion spécifique des erreurs (procédures stockées, tables, etc.)
        if ($_.Exception.Message -match "procédure stockée" -or $_.Exception.Message -match "table" -or $_.Exception.Message -match "vue" -or $_.Exception.Message -match "fonction") {
            Write-Host "Erreur spécifique détectée : $($_.Exception.Message)"
        }
        # Choisir de continuer ou d'arrêter l'exécution
        # break # Décommenter pour arrêter en cas d'erreur
    }
}

# Supprimer les fichiers temporaires
foreach ($fichierTemp in $fichiersTemporaires) {
    Remove-Item -Path $fichierTemp -Force
}