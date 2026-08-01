# Insiders Customer Segmentation

[![Python](https://img.shields.io/badge/Python-3.11-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![scikit-learn](https://img.shields.io/badge/scikit--learn-1.7-F7931E?logo=scikitlearn&logoColor=white)](https://scikit-learn.org/)
[![AWS](https://img.shields.io/badge/AWS-S3%20%7C%20EC2%20%7C%20RDS-232F3E?logo=amazonaws&logoColor=white)](https://aws.amazon.com/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?logo=postgresql&logoColor=white)](https://www.postgresql.org/)

End-to-end customer segmentation for an e-commerce loyalty program. The project converts transaction-level data into actionable customer groups, identifies the highest-value **Insiders** segment, and publishes the results through an automated AWS pipeline and Metabase.

> Monetary values use the source dataset's currency, which is not documented in this repository.

## Project Overview

This project supports a loyalty-program decision: which customers should be prioritized, retained, reactivated, upsold, or monitored for operational risk? It covers exploratory analysis, customer-level feature engineering, unsupervised model comparison, cluster profiling, scheduled execution, and delivery of the resulting segments to a BI layer.

The primary analysis is [`notebooks/c10_lr_validation_of_hypothesis_v2.ipynb`](notebooks/c10_lr_validation_of_hypothesis_v2.ipynb). The production implementation is [`src/models/c10_lr_deploy.ipynb`](src/models/c10_lr_deploy.ipynb).

## Business Problem

The business needs a reliable way to select customers for an **Insiders** loyalty program without using revenue alone. The solution groups customers according to value, recency, purchasing volume, purchase frequency, and returns, producing segments that can drive differentiated CRM and operational actions.

## Business Context

Segmentation replaces one-size-fits-all campaigns with targeted decisions. High-value active customers can receive retention benefits, low-value but active customers can be upsold, dormant customers can enter win-back campaigns, and high-return groups can be monitored as an operational-cost risk. Cluster labels are ranked by average gross revenue to make the output accessible to non-technical stakeholders.

## Dataset

The input is an e-commerce transaction dataset available locally at `data/raw/Ecommerce.csv` for development and in Amazon S3 in production. The primary notebook records **541,909 transactions** and the following source fields:

| Field | Description |
| --- | --- |
| `InvoiceNo` | Invoice/transaction identifier |
| `StockCode` | Product identifier |
| `Description` | Product description |
| `Quantity` | Purchased or returned quantity (negative for returns) |
| `InvoiceDate` | Transaction date |
| `UnitPrice` | Item unit price |
| `CustomerID` | Customer identifier |
| `Country` | Customer country |

The final modeling table is customer-level and contains **5,695 customers** after preprocessing and removal of incomplete profiles.

## Methodology

### Business Understanding

The task is unsupervised: the objective is an interpretable and actionable customer segmentation, not a supervised prediction. The business assumptions are that high value, recent activity, purchase volume/frequency, and returns help distinguish loyalty-program candidates.

### Data Collection and Cleaning

- Standardized column names to `snake_case` and converted dates/IDs to appropriate types.
- Recovered missing customer IDs by assigning an auxiliary customer ID per invoice, preserving usable transactions.
- Retained records with `unit_price >= 0.04`.
- Removed non-product stock codes, including postage, discounts, fees, and manual adjustments.
- Excluded `European Community` and `Unspecified` country values.
- Removed customer `16446`, identified in EDA as anomalous because of an extreme return pattern.
- Split positive-quantity purchases from negative-quantity returns.

### Exploratory Data Analysis

The notebooks assess dataset dimensions, types, missingness, descriptive statistics, distributions, outliers, and feature relationships. They identify long-tailed customer-level measures and investigate anomalous observations before modeling. Generated profiling reports are available in [`reports/`](reports/), and the hypothesis mind map is at [`reports/figures/Hypothesis_Mindmap.png`](reports/figures/Hypothesis_Mindmap.png).

### Feature Engineering and Selection

The final model uses customer-level features selected for business relevance while avoiding redundant derived metrics:

| Feature | Definition |
| --- | --- |
| `gross_revenue` | Sum of `quantity × unit_price` for purchases |
| `recency_days` | Days since the customer's latest purchase, relative to the dataset maximum date |
| `qtde_products` | Count of purchased product records |
| `frequency` | Distinct invoices divided by active days, with a zero-day safeguard |
| `qtde_returns` | Absolute sum of returned quantities; zero when no return exists |

Earlier notebooks also explore invoice count, item count, average ticket, average recency, and basket-size features. The final selection retains the features that best balance customer behavior coverage, redundancy, and interpretability.

### Data Preparation and Scaling

Each final numeric feature is independently transformed with `MinMaxScaler` to `[0, 1]`, preventing large-magnitude revenue and volume measures from dominating distance-based clustering. Fitted scalers are serialized and versioned in S3 for production reuse.

### Dimensionality Reduction

The analysis examines the original scaled feature space, PCA, t-SNE, UMAP, and a Random Forest leaf embedding followed by UMAP. PCA is explicitly considered unsuitable because its 2D projection does not reveal well-separated groups. The final solution uses a 2D UMAP embedding.

### Clustering, Hyperparameter Tuning, and Evaluation

The experimentation evaluates:

- K-Means
- Gaussian Mixture Models (GMM)
- Agglomerative hierarchical clustering with Ward linkage
- DBSCAN in the broader experimentation notebooks

For K-Means, GMM, and hierarchical clustering, cluster counts are evaluated principally from 2 to 20. DBSCAN exploration uses a k-nearest-neighbor distance plot and searches `eps` and `min_samples`. The main internal metric is the Euclidean **silhouette score**, supported by silhouette plots and stakeholder interpretability.

### Final Model Selection and Cluster Profiling

The final configuration is **K-Means with 10 clusters over a 2D UMAP embedding** of the five scaled customer features (`random_state=42`, `n_init=10`). The primary validation notebook records a **silhouette score of 0.481**. Although `k=15` achieved approximately `0.513`, `k=10` was selected for its more manageable, business-friendly segmentation.

Clusters are ranked by average gross revenue and relabelled from 1 (highest average revenue) to 10. Profiles contain customer count/share and the average revenue, recency, product count, frequency, and returns for each group.

### Business Hypothesis Validation

Post-clustering analysis tests or frames hypotheses about whether Insiders contribute disproportionately to product volume and revenue and whether their return behavior is below the customer-base average. The repository also proposes hypotheses requiring payment, demographic, product-weight, and delivery-distance data; these remain **TODO** because those attributes are not included in the supplied dataset. No A/B-test result or causal program-lift estimate is present in the repository.

## Results

| Item | Result |
| --- | --- |
| Final algorithm | K-Means |
| Representation | UMAP, 2 dimensions |
| Inputs | Revenue, recency, product count, frequency, returns |
| Selected clusters | 10 |
| Silhouette score | 0.481 |
| Modeling population | 5,695 customers |

The recorded analysis describes, among others:

| Profile | Share | Key characteristics | Action |
| --- | ---: | --- | --- |
| Premium high-value customers | 14.5% | ~6,104 average revenue, ~6 days recency, ~236 products | Top-priority loyalty segment |
| Active mid-value customers | 16.2% | ~1,810 average revenue, ~27 days recency | Retain and increase lifetime value |
| Moderate-value regular buyers | 8.9% | ~1,453 average revenue, ~69 days recency | Reactivation opportunity |
| Dormant high-return customers | 6.0% | ~337 days recency and elevated returns | Churn-risk campaign |
| High-return heavy buyers | 6.6% | ~203 average returns and ~311 days recency | Operational-risk monitoring |
| Low-value recent customers | 8.7% | ~601 average revenue but ~24 days recency | Upsell opportunity |
| Low-value infrequent buyers | 11.8% | ~529 average revenue and ~247 days recency | Lowest-priority segment |

**TODO:** Add a verified Insiders revenue-contribution percentage. The repository includes the calculation but does not persist its final result in the primary notebook output.

## Production Architecture

```text
Amazon S3
   │ Raw CSV and versioned model artifacts
   ▼
Amazon EC2
   │ Daily cron → run_model_ec2.sh → Papermill
   ▼
Automated Clustering Pipeline
   │ Cleaning → features → scalers → UMAP → K-Means → profiling
   ▼
Amazon RDS (PostgreSQL)
   │ insiders table
   ▼
Metabase Dashboards
   ▼
Business Users
```

| Component | Responsibility |
| --- | --- |
| Amazon S3 | Stores the raw CSV and versioned scalers, UMAP reducer, and K-Means model. |
| Amazon EC2 | Hosts the repository and executes the scheduled pipeline. [`run_model_ec2.sh`](run_model_ec2.sh) invokes the deploy notebook with Papermill and writes timestamped reports. |
| Automated pipeline | Reads S3 data, applies preprocessing and saved transformations, assigns clusters, and creates customer profiles. |
| Amazon RDS / PostgreSQL | Stores `insiders` with engineered features, `cluster`, `model_version`, and `prediction_date`. `(customer_id, model_version)` is the primary key; loading appends only keys not already present. |
| Metabase | Connects to PostgreSQL and exposes filtering and visualization for business users. |

## Dashboards

Metabase consumes the `insiders` PostgreSQL table. Suitable dashboard views include customer count/share by cluster; revenue and volume contribution; recency, frequency, and returns across clusters; customer-level campaign lists; and model version/prediction-date monitoring.

**TODO — screenshot placement:** add a publishable Metabase screenshot immediately below this paragraph, e.g. `reports/figures/metabase_dashboard.png`. No dashboard image is currently in the repository.

## Project Structure

```text
.
├── data/
│   ├── raw/Ecommerce.csv                         # Development input
│   └── processed/insiders_db.sqlite              # Local development output
├── notebooks/
│   ├── c10_lr_validation_of_hypothesis_v2.ipynb # Main experiments and analysis
│   └── c00...c10_*.ipynb                        # Iterative notebooks
├── reports/                                      # Profile reports and figures
├── src/
│   ├── data/load_data.py                         # Local/S3-compatible CSV loader
│   ├── features/transform_columns.py             # Column standardization
│   ├── features/*.pkl                            # Local scaler artifacts
│   └── models/c10_lr_deploy.ipynb                # Production pipeline
├── run_model.sh                                  # Local Papermill runner
├── run_model_ec2.sh                              # EC2 scheduled runner
├── requirements.txt
└── setup.py
```

## Technologies Used

| Category | Technologies |
| --- | --- |
| Programming language | Python 3.11 |
| Data processing | pandas, NumPy |
| Machine learning | scikit-learn, UMAP-learn, SciPy |
| Visualization and analysis | Jupyter, Matplotlib, Seaborn, Plotly, Yellowbrick, NetworkX |
| Cloud | Amazon S3, Amazon EC2, Amazon RDS |
| Databases | PostgreSQL (production), SQLite (local development) |
| Deployment / DevOps | Papermill, Bash, cron |
| Configuration / connectivity | SQLAlchemy, psycopg2, python-dotenv, s3fs |
| BI layer | Metabase |

## How to Run

### Local analysis

```bash
git clone <repository-url>
cd insiders_clustering
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
pip install -e .
jupyter notebook notebooks/c10_lr_validation_of_hypothesis_v2.ipynb
```

Ensure `data/raw/Ecommerce.csv` is present. Some optional exploratory notebook packages—such as `yellowbrick`, `plotly`, `seaborn`, `scipy`, `networkx`, and `ydata-profiling`—are imported but not pinned in `requirements.txt`; install them as needed. **TODO:** reconcile all notebook dependencies into a locked reproducible environment.

### Local pipeline execution

Run the deploy notebook with Papermill and save a timestamped executed notebook under `reports/`:

```bash
bash run_model.sh
```

The deploy notebook targets S3/RDS by default. For local execution, use its commented SQLite connection option and local artifacts.

### Production deployment

On EC2, the runner expects the project under `/home/ubuntu/insiders_clustering` and executes:

```bash
bash /home/ubuntu/insiders_clustering/run_model_ec2.sh
```

Configure cron to invoke this script daily. Provide S3 access, RDS connectivity, and non-committed credentials:

```dotenv
DB_HOST=TODO
DB_PORT=5432
DB_NAME=TODO
DB_USER=TODO
DB_PASSWORD=TODO
```

## Future Improvements

- Refactor notebook production logic into tested Python modules and orchestrate it with a workflow tool.
- Add schema validation, structured logging, retries, alerting, and data-quality checks.
- Track immutable data and artifact versions; add cluster-drift and model-quality monitoring.
- Add experiment tracking, unit/integration tests, and a complete dependency lock file.
- Enrich the dataset with customer, product, payment, and channel attributes to test outstanding hypotheses.
- Evaluate robust transformations for skewed features and assess segmentation stability over time.
- Add safe-to-publish Metabase screenshots or a dashboard link.
- Validate campaign impact using controlled experiments.

## Author

**Leonam Miranda**

Data Science / Machine Learning portfolio project.

**TODO:** Add LinkedIn, GitHub, portfolio URL, and contact details before publishing.

## License

All rights reserved. See [LICENSE](LICENSE).
