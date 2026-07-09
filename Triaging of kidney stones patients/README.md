# AI-Based Triage for Kidney Stone Patients

**Author:** Umar Shadab Butt  
**Degree:** MSc Data Science and Analytics, Cardiff University  
---

## Overview

Machine learning pipeline to predict clinical triage decisions for kidney stone patients using patient-reported outcomes (PROMs) and clinical data.

**Models:** Logistic Regression, Random Forest, XGBoost  
**Dataset:** 121 visits, 4 longitudinal timepoints, University Hospital of Wales (2021–2024)

---

## Results

### Visit-1 (Initial Triage)
- **Best Model:** Logistic Regression + SMOTE
- **Accuracy:** 92% | **Recall:** 88% | **F1:** 0.82

### Visit-2 (Follow-up)
- **Best Model:** Balanced Random Forest
- **Accuracy:** 68% | **Recall:** 83% | **F1:** 0.54
- Note: Lower due to severe class imbalance

---

## Key Finding

Patient-reported outcomes (PROM domains) improve triage predictions beyond clinical variables alone. Psycho-social factors gain importance at follow-up.

---

## How to Use

### Install
```bash
pip install -r requirements.txt
```

### Run
Open `Code.ipynb` and execute cells sequentially.

---

## File Structure

```
dissertation/
├── README.md (this file)
├── Code.ipynb (fully documented code + results)
└──  requirements.txt (Python dependencies)
```

---

## Methodology

1. **Data Preprocessing:** Missing value imputation, feature scaling, one-hot encoding
2. **Class Imbalance:** SMOTE applied within cross-validation
3. **Model Training:** GridSearchCV + 5-fold stratified cross-validation
4. **Evaluation:** Classification metrics, confusion matrix, ROC-AUC, permutation importance
5. **Feature Analysis:** Identify key predictors via permutation importance

---

## Limitations

- Single-centre dataset (121 visits)
- Severe class imbalance (especially Visit-2)
- No external validation

---

## Next Steps

- Multicentre prospective data collection
- Real-world validation in NHS clinical pathways
- Continuous model monitoring post-deployment
