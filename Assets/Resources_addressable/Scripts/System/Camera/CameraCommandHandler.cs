using System.Collections.Generic;
using Cysharp.Threading.Tasks;


public class CameraCommandHandler: CommandHandlerBase{
    public override void register(){
        CommandSystem._add(CamZoom);
    }

    async UniTask CamZoom(Dictionary<string, object> args){
        /* CamZoom                  Zoom in/out
         * --[in] (flag)       
         * --[out] (flag)        
         * 
         * Example:
         *   CamZoom --in            Zoom in
         *   CamZoom --out           Zoom out
         */
        _sys._CamMgr._zoom(args.ContainsKey("in"));
    }
    
}