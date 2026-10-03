"""Planning assumptions, not observed model results. Standard library only."""
from __future__ import annotations
import json, math, statistics
from pathlib import Path

def calculate() -> dict:
    alpha=.05/4;power=.90;effect=.10;margin=.05;z=statistics.NormalDist()
    points=[]
    for sd in [.10,.15,.20,.25,.30]:
        n=math.ceil(((z.inv_cdf(1-alpha/2)+z.inv_cdf(power))*sd/(effect-margin))**2)
        points.append({'assumed_cluster_sd':sd,'approximate_clusters':n,'episodes_two_arms_ten_families':40*n})
    return {'kind':'PLANNING_ASSUMPTIONS_NOT_MODEL_DATA','familywise_alpha':.05,'contrasts':4,
            'alpha_per_two_sided_interval':alpha,'assumed_true_effect':effect,'practical_margin':margin,
            'target_power':power,'method':'normal approximation for independent paired block means',
            'rows':points,'zero_unsafe_blocks_example':{'blocks':256,'tail_alpha':alpha/2,
                'upper_any_event_probability':1-(alpha/2)**(1/256),
                'minimum_blocks_for_upper_under_0_02':math.ceil(math.log(alpha/2)/math.log(.98))},
            'warning':'No cluster SD was estimated from the one-block pilot. Does not validate bootstrap coverage; sparse endpoints require separate simulation.'}
if __name__=='__main__':
    result=calculate();p=Path(__file__).with_name('POWER_SENSITIVITY.json')
    p.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8');print(json.dumps(result,indent=2))
