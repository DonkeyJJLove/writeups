from __future__ import annotations
import argparse,json,sys
from .research_runtime import ensure_research_endpoint,stop_owned_research,endpoint_info,listener_process,RuntimeErrorSafe

def main(argv=None):
    p=argparse.ArgumentParser(description='Safe research endpoint lifecycle; production 8772 is read-only.')
    sub=p.add_subparsers(dest='cmd',required=True)
    up=sub.add_parser('up');up.add_argument('--prod-port',type=int,default=8772);up.add_argument('--research-port',type=int,default=8773);up.add_argument('--context',type=int,default=8192)
    st=sub.add_parser('status');st.add_argument('--research-port',type=int,default=8773)
    dn=sub.add_parser('down');dn.add_argument('--research-port',type=int,default=8773)
    a=p.parse_args(argv)
    try:
        if a.cmd=='up':
            lease=ensure_research_endpoint(a.prod_port,a.research_port,a.context)
            print(json.dumps({'status':'READY','url':lease.url,'pid':lease.pid,'started_here':lease.started_here},indent=2));return 0
        if a.cmd=='status':
            print(json.dumps({'endpoint':endpoint_info(a.research_port),'process':listener_process(a.research_port)},ensure_ascii=False,indent=2));return 0
        if a.cmd=='down':
            print(json.dumps(stop_owned_research(a.research_port),ensure_ascii=False,indent=2));return 0
    except RuntimeErrorSafe as e:
        print('ERROR: '+str(e),file=sys.stderr);return 2
    return 0

if __name__=='__main__': raise SystemExit(main())
