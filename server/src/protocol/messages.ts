export type ClientMessage =
  | { type: 'create_room'; name: string; language: string }
  | { type: 'join_room'; code: string; name: string; language?: string }
  | { type: 'leave_room' } | { type: 'start_game' }
  | { type: 'choose_word'; wordId: number }
  | { type: 'stroke_batch'; strokes: Stroke[] }
  | { type: 'undo' } | { type: 'clear' }
  | { type: 'guess'; text: string }
  | { type: 'reconnect'; token: string };
export type Stroke = { points: {x:number;y:number}[]; color:string; width:number; erase:boolean };
export function parseMessage(raw: string): ClientMessage {
  if (raw.length > 24_000) throw new Error('Message too large');
  const m = JSON.parse(raw) as Record<string, unknown>;
  if (!m || typeof m.type !== 'string') throw new Error('Invalid message');
  const str=(key:string,max=80)=>{if(typeof m[key]!=='string'||!(m[key] as string).trim()||(m[key] as string).length>max)throw new Error(`Invalid ${key}`); return (m[key] as string).trim();};
  switch(m.type) {
    case 'create_room': return {type:m.type,name:str('name',24),language:str('language',16)};
    case 'join_room': return {type:m.type,code:str('code',6).toUpperCase(),name:str('name',24),language:typeof m.language==='string'?m.language:'en'};
    case 'leave_room': case 'start_game': case 'undo': case 'clear': return {type:m.type};
    case 'choose_word': if(!Number.isInteger(m.wordId)) throw new Error('Invalid word choice'); return {type:m.type,wordId:m.wordId as number};
    case 'guess': return {type:m.type,text:str('text',100)};
    case 'reconnect': return {type:m.type,token:str('token',100)};
    case 'stroke_batch':
      if(!Array.isArray(m.strokes)||m.strokes.length>50) throw new Error('Invalid strokes');
      for (const item of m.strokes) {
        if (!item || typeof item !== 'object') throw new Error('Invalid stroke');
        const s=item as Record<string,unknown>;
        if (typeof s.color!=='string'||!/^#[0-9a-fA-F]{8}$/.test(s.color)||typeof s.width!=='number'||!Number.isFinite(s.width)||s.width<1||s.width>60||typeof s.erase!=='boolean'||!Array.isArray(s.points)||s.points.length<1||s.points.length>500) throw new Error('Invalid stroke');
        for (const point of s.points) { if(!point||typeof point!=='object')throw new Error('Invalid point'); const p=point as Record<string,unknown>; if(typeof p.x!=='number'||typeof p.y!=='number'||!Number.isFinite(p.x)||!Number.isFinite(p.y)||p.x<0||p.x>1||p.y<0||p.y>1)throw new Error('Invalid point'); }
      }
      return {type:m.type,strokes:m.strokes as Stroke[]};
    default: throw new Error('Unknown message type');
  }
}
