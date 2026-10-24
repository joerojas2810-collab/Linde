from pathlib import Path
from PIL import Image, ImageDraw
import json

OUT = Path(__file__).resolve().parent
PKG = OUT.parents[1]
SRC = PKG / 'base_proyecto/Linde/cenital/arte/equipo/ataque'
def cell(im, r, c, n=48):
    return im.crop((c*n, r*n, (c+1)*n, (r+1)*n))

def main():
    names = ['base/ataque_sin_espada.png','base/capas/tunica.png',
             'base/capas/botas.png','base/capas/piel.png',
             'equipo_ligera_torso_ataque.png','equipo_media_torso_ataque.png',
             'equipo_pesada_torso_ataque.png','equipo_ligera_botas_ataque.png',
             'equipo_media_botas_ataque.png','escudo_ataque.png','espada_ataque.png',
             'referencia/ataque.png']
    dest=OUT/'lotes/E01_v001/previews'; dest.mkdir(parents=True,exist_ok=True)
    canvas=Image.new('RGB',(12*200,4*210),(40,46,54)); d=ImageDraw.Draw(canvas)
    for j,name in enumerate(names):
        im=Image.open(SRC/name).convert('RGBA')
        for r in range(4):
            strip=im.crop((0,r*48,192,(r+1)*48)).resize((192,48),Image.Resampling.NEAREST)
            # Show all four poses vertically, at x3.
            for c in range(4):
                pic=cell(im,r,c).resize((144,144),Image.Resampling.NEAREST)
                # each source column is a separate full page instead below
    for r in range(4):
        canvas=Image.new('RGB',(len(names)*154,4*174),(40,46,54)); d=ImageDraw.Draw(canvas)
        for j,name in enumerate(names):
            im=Image.open(SRC/name).convert('RGBA')
            for c in range(4):
                pic=cell(im,r,c).resize((144,144),Image.Resampling.NEAREST)
                canvas.paste(pic,(j*154,c*174+26),pic)
                d.text((j*154+2,c*174+2),name.split('/')[-1].replace('equipo_','')[:24],fill='white')
                d.text((j*154+2,c*174+14),f'[{r},{c}]',fill='white')
        canvas.save(dest/f'E01_entradas_fila_{r}.png')
    for r,c in [(0,2),(1,2),(1,3),(3,2)]:
        print('CELL',r,c)
        for name in ['base/capas/tunica.png','base/capas/botas.png','base/capas/piel.png']:
            im=cell(Image.open(SRC/name).convert('RGBA'),r,c)
            print(name,im.getbbox())
            for y in range(26,47):
                line=''.join('#' if im.getpixel((x,y))[3] else '.' for x in range(6,42))
                if '#' in line: print(y,line)

if __name__=='__main__': main()
