# 📜 Advanced Security Report Script per Azure DevOps

## 📌 Descrizione
Questo script PowerShell consente di **recuperare e processare gli alert di sicurezza avanzata** relativi a un repository ospitato in **Azure DevOps**.  
Utilizza le API REST di Azure DevOps e genera automaticamente un report in formato CSV, che può essere pubblicato come artefatto della pipeline.  

L’obiettivo principale è semplificare la raccolta e l’analisi degli **alert di sicurezza** generati da strumenti come **Advanced Security Dependency Scanning** o simili, evitando attività manuali e centralizzando le informazioni in un file consultabile.

---

## ⚙️ Funzionalità principali
- ✅ Recupera automaticamente le variabili di ambiente della pipeline di Azure DevOps:
  - **Organizzazione**
  - **Progetto**
  - **Repository**
  - **Token di accesso (OAuth)**  
- ✅ Si autentica alle API di Azure DevOps utilizzando l’**access token temporaneo** messo a disposizione dalla pipeline.  
- ✅ Recupera l’ID del repository tramite le API REST.  
- ✅ Interroga gli endpoint dedicati alla **Advanced Security** per estrarre tutti gli alert di sicurezza.  
- ✅ Processa le risposte API, trasformandole in oggetti PowerShell leggibili.  
- ✅ Esporta i dati finali in un file **CSV** con encoding UTF-8.  
- ✅ Organizza i report in cartelle con timestamp per una migliore tracciabilità.  
- ✅ Pubblica automaticamente il CSV come **artefatto della pipeline**.  

---

## 📂 Output
Lo script genera una cartella con nome:  

AdvancedSecurityReport_<repository>_<timestamp>

All’interno troverai un file CSV con nome simile a:  

AdvancedSecurityReport_20250820_101755.csv


Il file contiene gli alert estratti, oppure – se non ne sono presenti – una riga con valori `N/A`.

---

## 🔑 Requisiti
Lo script è pensato per essere eseguito in una **pipeline di Azure DevOps**.  
Assicurati che siano soddisfatte le seguenti condizioni:  

- **PowerShell** installato (versione 5.1 o superiore, oppure PowerShell Core).  
- Pipeline configurata su Azure DevOps.  
- L’opzione **“Allow scripts to access the OAuth token”** deve essere abilitata.  
- Le seguenti variabili di ambiente devono essere disponibili (Azure DevOps le fornisce automaticamente):  

| Variabile | Descrizione |
|-----------|-------------|
| `SYSTEM_TEAMFOUNDATIONCOLLECTIONURI` | URL della tua organizzazione DevOps |
| `SYSTEM_TEAMPROJECT` | Nome del progetto DevOps |
| `BUILD_REPOSITORY_NAME` | Nome del repository in build |
| `SYSTEM_ACCESSTOKEN` | Token OAuth temporaneo per autenticarsi alle API |

---

## 🚀 Utilizzo
1. Aggiungi lo script come step in una pipeline **YAML** o **Classic** su Azure DevOps.  
2. Verifica di aver abilitato l’uso del token OAuth.  
3. Esegui la pipeline.  
4. Al termine, troverai:  
   - Una cartella contenente il file CSV con il report.  
   - L’artefatto pubblicato nella pipeline (`AdvancedSecurityReports`).  

---

## ⚠️ Note di Sicurezza
- Lo script **non contiene dati sensibili in chiaro**.  
- Il token OAuth (`SYSTEM_ACCESSTOKEN`) è temporaneo e viene gestito in memoria, **non viene salvato su file**.  
- Evita di aggiungere log o stampe che contengano l’header di autenticazione o i contenuti completi delle API, poiché potrebbero includere informazioni sensibili (es. email, path interni).  
- Se usi i log di debug, ricorda di **mascherare i dati riservati** con le funzionalità native di Azure DevOps (`##vso[task.setsecret]`).  

---

## 📖 Esempio di pipeline (YAML)

steps:

task: PowerShell@2
inputs:
targetType: 'filePath'
filePath: 'scripts/AdvancedSecurityReport.ps1'
displayName: 'Generate Advanced Security Report'


---

## 🛠️ Estendibilità
Lo script può essere facilmente adattato per:  
- Esportare i dati in **formati diversi** (JSON, Excel, ecc.).  
- Inviare automaticamente il report via **email o Teams**.  
- Integrare controlli di sicurezza personalizzati.  

---

## 📜 Licenza
Questo progetto è distribuito sotto licenza **MIT**.  
Sentiti libero di modificarlo e riutilizzarlo in base alle tue esigenze.  







