public class ObjectAsImpactTrigger: ObjectAsBase{
    public ObjectAsImpactTrigger(ObjectBase Base): base(Base){}

    public override void _apply(){
        BaseClass._sys._ObjSys._runtimeID2ImpactTriggerBase.Add(_Base._runtimeID, _Base);
    }

    public override void _clear(){
        BaseClass._sys._ObjSys._runtimeID2ImpactTriggerBase.Remove(_Base._runtimeID);
    }
}