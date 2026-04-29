# Cost Estimate

Approximate monthly cost to run this toolkit in a single AWS account (us-east-1, as of 2024). Costs scale with usage — figures below assume a mid-sized environment.

---

## Per-Service Breakdown

### GuardDuty
Priced per GB of data analyzed (CloudTrail events, DNS logs, VPC flow logs).

| Volume | Monthly Cost |
|--------|-------------|
| Small (< 500 GB/month) | ~$30–$80 |
| Medium (500 GB–2 TB/month) | ~$80–$300 |
| Large (> 2 TB/month) | ~$300+ |

S3 Protection and Malware Protection add ~20–30% if enabled.

### Security Hub
$0.0010 per finding ingested per month (after 10,000 free findings).

| Environment size | Est. findings/month | Monthly Cost |
|-----------------|---------------------|-------------|
| Small | ~5,000 | ~$0 (free tier) |
| Medium | ~20,000 | ~$10 |
| Large | ~100,000 | ~$90 |

Standards subscriptions (CIS, NIST, AWS Foundational) are included at no extra charge.

### CloudTrail
- First trail in a region: **free**
- Management events on additional trails: $2.00 per 100,000 events
- Data events (S3 object-level): $0.10 per 100,000 events

| Usage | Monthly Cost |
|-------|-------------|
| Management events only | ~$0–$5 |
| + S3 data events (active buckets) | ~$10–$50 |

### AWS Config
$0.003 per configuration item recorded.

| Resources tracked | Monthly Cost |
|------------------|-------------|
| ~100 resources | ~$9 |
| ~500 resources | ~$45 |
| ~1,000 resources | ~$90 |

### VPC Flow Logs (CloudWatch)
$0.50 per GB ingested + $0.03 per GB stored.

| Traffic volume | Monthly Cost |
|---------------|-------------|
| Low (< 10 GB/month) | ~$5–$10 |
| Medium (10–50 GB/month) | ~$20–$50 |
| High (> 50 GB/month) | ~$50+ |

Sending to S3 instead of CloudWatch reduces cost significantly.

### S3 (Log Storage)
~$0.023 per GB/month (Standard). CloudTrail logs compress well — typically 1–5 GB/month for a small account.

| Retention | Est. storage | Monthly Cost |
|-----------|-------------|-------------|
| 1 year | ~12–60 GB | ~$0.30–$1.40 |

### SNS
Effectively free at this scale — $0.50 per 1 million requests.

---

## Total Monthly Estimate

| Environment Size | Approx. Monthly Cost |
|-----------------|---------------------|
| Small (startup, single account) | **$50–$150** |
| Medium (100–500 resources, active traffic) | **$150–$500** |
| Large (enterprise, multi-account) | **$500–$1,500+** |

---

## Cost vs. Risk Reduction

For context: the average cost of a cloud data breach is **$4.45M** (IBM Cost of Data Breach Report 2023). The controls in this toolkit — at $50–$500/month — reduce the probability and impact of the most common cloud incident types.

At $150/month ($1,800/year), the break-even point is a **0.04% reduction in annual breach probability** for a $4.45M expected loss scenario.

That is not a difficult ROI argument to make.

---

## Cost Optimization Tips

- **Send VPC flow logs to S3** instead of CloudWatch — reduces ingestion cost by ~60%
- **Use S3 Intelligent-Tiering** for log storage — automatically moves older logs to cheaper tiers
- **Set Config recorder to record only specific resource types** if full recording is too expensive
- **GuardDuty 30-day free trial** — enable it, measure actual data volume, then estimate ongoing cost before committing
