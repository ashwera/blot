import type { Stroke } from '../protocol/messages.js';
export type Phase='LOBBY'|'CHOOSING_WORD'|'DRAWING'|'ROUND_END'|'GAME_END';
export type Player={id:string;name:string;token:string;score:number;connected:boolean;socket?: import('ws').WebSocket};
export type Room={code:string;hostId:string;players:Player[];language:string;phase:Phase;round:number;drawerIndex:number;word?:string;choices?:string[];strokes:Stroke[];guessed:Set<string>;deadline?:number;timer?:ReturnType<typeof setTimeout>;hinted:number};
export const normalize=(s:string)=>s.normalize('NFC').toLocaleLowerCase().trim().replace(/[\p{P}\p{S}]+/gu,' ').replace(/\s+/g,' ').trim();
export function distance(a:string,b:string):number { const x=[...normalize(a)],y=[...normalize(b)]; let prev=Array.from({length:y.length+1},(_,i)=>i); for(let i=1;i<=x.length;i++){const row=[i];for(let j=1;j<=y.length;j++)row[j]=Math.min(row[j-1]+1,prev[j]+1,prev[j-1]+(x[i-1]===y[j-1]?0:1));prev=row;}return prev[y.length]; }
export function isNearGuess(guess:string,word:string){const a=normalize(guess),b=normalize(word);return a.length>2&&Math.abs(a.length-b.length)<=2&&distance(a,b)<=Math.max(1,Math.floor(b.length*.22));}
export function scoreForGuess(elapsed:number,duration:number){return Math.max(100,Math.round(1000*(1-Math.min(elapsed,duration)/duration*.75)));}
export function maskWord(word:string,reveal:number){const chars=[...word];let n=0;return chars.map(c=>/\p{L}/u.test(c)?(n++<reveal?c:'_'):c).join(' ');}
