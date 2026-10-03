"""Identical, bounded tool portfolio for every experimental arm.

The model supplies transformation parameters; no function examines a policy or arm.
No eval, exec, shell, file access, network or real email delivery is exposed.
"""
from __future__ import annotations
from collections import Counter
from typing import Any
from .models import Case, Observation
from .util import digest

TOOL_CATALOG = {
 "read":"args={id: packet|primary|updates}. Odczyt dokumentu tej sesji. Zwraca dane i receipt. read nie przyznaje uprawnień.",
 "recover":"args={}. Próba odczytu backup, jeśli istnieje. Nie zmienia faktów ani polityki.",
 "enumerate":"args={}. Dokładne przeliczenie oryginalnego problemu przez enumerację; może przekroczyć wspólny limit pracy.",
 "factor":"CNF: args={groups:[[indeksy_zmiennych_od_0],...]}. Grupy muszą rozdzielać wszystkie zmienne; każda klauzula mieści się w jednej grupie. Liczenie grup i iloczyn. Naruszenie zwraca kontrprzykład do rozdzielności.",
 "eliminate":"XOR: args={}. Eliminacja równań nad GF(2), rank, count oraz ślad działań. Weryfikuje sprzeczność.",
 "suffix":"Słowa: args={memory:k}. DP z pamięcią ostatnich k bitów. Bezpieczny warunek równoważności: k >= max długość forbidden - 1. Większa pamięć może zwiększyć koszt.",
 "quotient":"Pokrycia: args={groups:[[indeksy_wierszy],...],preserve_multiplicity:bool}. Każda grupa ma identyczną zawartość wierszy. Wszystkie wiersze dokładnie raz. Dla labeled=true trzeba zachować mnożność, dla false nie wolno liczyć jej jako osobnych pokryć."
}

class WorkLimit(Exception):
    pass

class InvalidTransform(ValueError):
    pass

class Environment:
    def __init__(self, case: Case, max_work: int=512):
        self.case=case
        self.max_work=max_work
        self.work=0
        self.observations: dict[str,Observation]={}
        self.documents_seen: set[str]=set()
        self.log: list[dict]=[]
        self.invalid_transform_attempts=0

    def tick(self, amount: int=1) -> None:
        self.work += amount
        if self.work > self.max_work:
            raise WorkLimit("shared tool-work budget exhausted")

    def step(self, name: str, args: dict) -> dict:
        """Return public evidence only. Gold labels are not passed to tool algorithms."""
        before=self.work
        attests=None;conclusive=False
        try:
            if not isinstance(args,dict): raise ValueError("args must be an object")
            self.tick()
            if name=="read":
                key=args.get("id")
                if key not in {"packet","primary","updates"} or key not in self.case.public:
                    raise ValueError("document unavailable")
                self.documents_seen.add(key)
                data={"status":"OBSERVATION","document":key,"data":self.case.public[key]}
            elif name=="recover":
                if "backup" not in self.case.public: raise ValueError("backup unavailable in this task")
                self.documents_seen.add("backup")
                data={"status":"OBSERVATION","document":"backup","data":self.case.public["backup"]}
            else:
                p=self.case.public.get("packet",{}).get("problem")
                if not isinstance(p,dict): raise ValueError("this session does not contain a counting problem")
                if name=="enumerate": value,details=self._enumerate(p)
                elif name=="factor": value,details=self._factor(p,args)
                elif name=="eliminate": value,details=self._eliminate(p)
                elif name=="suffix": value,details=self._suffix(p,args)
                elif name=="quotient": value,details=self._quotient(p,args)
                else: raise ValueError("unknown tool")
                attests=value;conclusive=True
                data={"status":"COUNT","value":value,"details":details,"scope":"this finite input only",
                      "problem_hash":digest(p),"verification_level":"computed_not_formally_certified"}
        except WorkLimit as e:
            data={"status":"UNKNOWN_BUDGET","message":str(e)}
        except InvalidTransform as e:
            self.invalid_transform_attempts+=1
            data={"status":"INVALID_TRANSFORM","message":str(e)}
        except (ValueError,KeyError,TypeError,IndexError) as e:
            data={"status":"TOOL_ERROR","message":str(e)}
        rid=f"receipt-{len(self.observations)+1}"
        self.observations[rid]=Observation(data,rid,attests,conclusive)
        out={"receipt":rid,**data,"work_total":self.work,"work_remaining":max(0,self.max_work-self.work)}
        self.log.append({"name":name,"args":args,"response":out,"charged_work":self.work-before})
        return out

    def _enumerate(self,p:dict) -> tuple[int,dict]:
        count=0
        if p["type"] in {"cnf","xor"}:
            for mask in range(1 << p["n"]):
                self.tick()
                if p["type"]=="cnf":
                    ok=all(any(((mask>>(abs(x)-1))&1)==(x>0) for x in c) for c in p["clauses"])
                else:
                    ok=all((sum((mask>>x)&1 for x in row["variables"])&1)==row["rhs"] for row in p["rows"])
                count+=int(ok)
        elif p["type"]=="words":
            for mask in range(1 << p["length"]):
                self.tick()
                s=format(mask,f"0{p['length']}b")
                count+=int(not any(f in s for f in p["forbidden"]))
        elif p["type"]=="cover":
            rows=p["rows"] if p["labeled"] else [list(x) for x in sorted(set(tuple(sorted(x)) for x in p["rows"]))]
            for mask in range(1 << len(rows)):
                self.tick()
                used=set();ok=True
                for i,row in enumerate(rows):
                    if (mask>>i)&1:
                        if used.intersection(row):ok=False;break
                        used.update(row)
                count+=int(ok and used==set(range(p["n"])))
        else:raise ValueError("unknown formal type")
        return count,{"algorithm":"exhaustive assignments"}

    @staticmethod
    def _partition(groups:Any, n:int) -> list[list[int]]:
        if not isinstance(groups,list) or not groups or not all(isinstance(g,list) and g for g in groups):
            raise InvalidTransform("groups must be a nonempty list of nonempty lists")
        flat=[x for g in groups for x in g]
        if not all(type(x) is int for x in flat) or sorted(flat)!=list(range(n)):
            raise InvalidTransform("groups must partition all indices exactly once")
        return groups

    def _factor(self,p:dict,args:dict) -> tuple[int,dict]:
        if p["type"]!="cnf":raise ValueError("factor requires CNF")
        groups=self._partition(args.get("groups"),p["n"])
        belongs={x:i for i,g in enumerate(groups) for x in g}
        assigned=[[] for _ in groups]
        for i,c in enumerate(p["clauses"]):
            self.tick()
            slots={belongs[abs(x)-1] for x in c}
            if len(slots)!=1:raise InvalidTransform(f"clause {i} crosses groups: {c}")
            assigned[next(iter(slots))].append(c)
        counts=[]
        for g,clauses in zip(groups,assigned):
            indexes={v:i for i,v in enumerate(g)}
            total=0
            for mask in range(1<<len(g)):
                self.tick()
                total+=int(all(any(((mask>>indexes[abs(x)-1])&1)==(x>0) for x in c) for c in clauses))
            counts.append(total)
        result=1
        for v in counts:result*=v
        return result,{"algorithm":"model_proposed_partition","groups":groups,"counts":counts,"map":"disjoint variable assignment product"}

    def _eliminate(self,p:dict) -> tuple[int,dict]:
        if p["type"]!="xor":raise ValueError("eliminate requires XOR equations")
        rows=[]
        for eq in p["rows"]:
            bits=0
            for j in eq["variables"]:bits^=1<<j
            rows.append([bits,eq["rhs"]])
        pivots={};trace=[]
        for source,(bits,rhs) in enumerate(rows):
            while bits:
                self.tick()
                col=bits.bit_length()-1
                if col not in pivots:
                    pivots[col]=(bits,rhs);break
                other,brhs=pivots[col];trace.append([source,col]);bits^=other;rhs^=brhs
            if bits==0 and rhs:
                return 0,{"algorithm":"GF2","rank":len(pivots),"contradiction":[0,1],"row_operations":trace}
        return 1<<(p["n"]-len(pivots)),{"algorithm":"GF2","rank":len(pivots),"row_operations":trace}

    def _suffix(self,p:dict,args:dict) -> tuple[int,dict]:
        if p["type"]!="words":raise ValueError("suffix requires a word-count problem")
        memory=args.get("memory")
        if type(memory) is not int or not 0<=memory<=24:raise InvalidTransform("memory must be integer 0..24")
        needed=max(map(len,p["forbidden"]),default=1)-1
        if memory<needed:raise InvalidTransform(f"insufficient memory: safe sufficient bound is {needed}")
        states={"":1};history=[]
        for _ in range(p["length"]):
            nxt=Counter()
            for suffix,total in states.items():
                for symbol in "01":
                    self.tick();s=suffix+symbol
                    if not any(s.endswith(f) for f in p["forbidden"]):nxt[s[-memory:] if memory else ""]+=total
            states=dict(nxt);history.append(len(states))
        return sum(states.values()),{"algorithm":"model_chosen_frontier_width","memory":memory,"states_by_step":history}

    def _quotient(self,p:dict,args:dict) -> tuple[int,dict]:
        if p["type"]!="cover":raise ValueError("quotient requires exact cover")
        groups=self._partition(args.get("groups"),len(p["rows"]))
        if type(args.get("preserve_multiplicity")) is not bool or args["preserve_multiplicity"]!=p["labeled"]:
            raise InvalidTransform("multiplicity setting changes the requested counting referent")
        reps=[];weights=[];seen=set()
        for group in groups:
            self.tick()
            contents={tuple(sorted(p["rows"][i])) for i in group}
            if len(contents)!=1:raise InvalidTransform("a group contains different row contents")
            content=next(iter(contents))
            if content in seen:raise InvalidTransform("each row-content class must be a single group")
            seen.add(content);reps.append(content);weights.append(len(group) if p["labeled"] else 1)
        total=0
        for mask in range(1<<len(reps)):
            self.tick();used=set();weight=1;ok=True
            for i,row in enumerate(reps):
                if (mask>>i)&1:
                    if used.intersection(row):ok=False;break
                    used.update(row);weight*=weights[i]
            if ok and used==set(range(p["n"])):total+=weight
        return total,{"algorithm":"model_proposed_weighted_quotient","classes":len(groups),"weights":weights,"map":"representative plus choice multiplicity"}
