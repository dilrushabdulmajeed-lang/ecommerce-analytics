# E-commerce Performance Review: GCC Electronics Store

**Period:** 15 Oct 2025 – 14 Oct 2026 (12 months) · **Prepared by:** dilrushabdulmajeed · **Data:** ClickHouse `analytics.ecom_*` (1.23M events, 23.7k orders)

> Portfolio note: the data is synthetic, generated with realistic behaviour (funnels, repeat purchasing, promotions). The SQL, dashboard and automation work exactly as they would against real event data.

## Summary

| Revenue | Orders | AOV | Customers | Repeat rate |
|---|---|---|---|---|
| AED 46.6M | 23,739 | AED 1,962 | 14,933 | 35% |

The store converts interest well (add-to-cart is the same on every device), but **loses revenue at mobile checkout and after the first order**. Fixing the mobile checkout alone is worth an estimated **AED 7.5M a year (+16%)**.

## Findings and recommendations

### 1. Mobile checkout loses more than half of buyers
| Device | Sessions | Add to cart | Checkout completion |
|---|---|---|---|
| Mobile | 263k (60%) | 16.6% | **46.4%** |
| Desktop | 134k | 16.9% | 78.2% |
| Tablet | 40k | 16.6% | 72.3% |

- Mobile shoppers add to cart **as often** as desktop shoppers, so interest isn't the problem. They abandon **at checkout**: about 13,000 mobile checkouts a year don't complete.
- **Recommendation:** audit the mobile checkout (form length, payment options such as Apple Pay, page speed, errors), then A/B test fixes.
- **Impact:** closing **half** the gap to desktop (46% → 62%) adds about **3,900 orders, or AED 7.5M a year (+16% revenue)**.

### 2. The White Friday promo bought one-time customers
| Acquisition | Customers | Repeat rate | Lifetime value |
|---|---|---|---|
| White Friday Promo (30% off) | 1,659 | **8.3%** | **AED 1,777** |
| All other channels | 13,274 | 38.5% | AED 3,287 |

- The Nov 2025 cohort shows the lowest retention of any month: **8.6% in month 1, falling to 2.3% by month 6**, against about 15% and 9% for a typical cohort.
- Promo customers are worth **46% less** over their lifetime. The discount attracted deal-seekers, not loyal buyers.
- **Recommendation:** next time, use a smaller first-order discount combined with a **second-purchase incentive** (for example, 10% off a second order within 30 days), and judge promos on 90-day LTV, not launch-week revenue.
- **Impact:** lifting promo repeat rate from 8% to 20% adds about **190 repeat customers (about AED 0.3M)** per campaign.

### 3. 394 high-value customers are slipping away
- The RFM model flags **394 "At Risk" customers**: on average **3.4 orders and AED 6,740 lifetime spend (2.2× the average customer)**, but no purchase for about **200 days**. 78 of them have spent AED 10k or more.
- Together they've spent **AED 2.66M**.
- **Recommendation:** a win-back programme. **Automated:** an n8n workflow exports this list every Monday with a suggested action (VIP personal call, or a 15% win-back code for the rest).
- **Impact:** reactivating 15% for one order each is worth about **AED 120k per campaign**, and it protects future revenue from the most valuable segment.

## Also noted
- **Revenue concentration:** the top 10% of customers generate **33%** of revenue, and the top 20% generate **52%**. Champions are 3.7% of customers but 10% of revenue, so keeping them is cheaper than replacing them.
- **Category mix:** Laptops (41%) and Phones (24%) drive two-thirds of revenue. Accessories sell as often but contribute only 1%, so they're a cross-sell opportunity at checkout, not a growth driver on their own.

## Next steps
1. Mobile checkout UX audit and A/B test. *Owner: Product · 4 weeks*
2. Redesign promo mechanics with a second-purchase incentive. *Owner: Marketing · before the next sale*
3. Launch the win-back programme using the weekly n8n export. *Owner: CRM · this week*
4. Track checkout completion by device and promo-cohort retention monthly on the dashboard.

---
*Dashboard: Metabase → "E-commerce Performance" · Automation: n8n "Weekly At-Risk customers export" · SQL: `sql/`, `metabase/questions/`*
