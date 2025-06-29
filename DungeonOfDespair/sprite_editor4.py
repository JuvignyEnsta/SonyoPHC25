# Editeur de sprite pour Sanyo PCH 25
import pygame as pg
import numpy as np
from typing import Callable
import sys
import os

filename = "sprite"

# Donc pour avoir un décalage des sprites pixel par pixel, on est obligé d'avoir quatre fois un décalage d'un pixel
# pour une animation lisse.
NB_FRAMES = 1   # Nombre de frames par sprites
SPRITE_WIDTH=16 # En nombre de pixels
SPRITE_HEIGHT=16 # En nombre de pixels
IND_PALETTE=0

BLACK        = (  0,  0,  0)
WHITE        = (255,255,255)
RED          = (255,  0,  0)
BLUE         = (  0,  0,255)
GREEN        = (  0,255,  0)
CYAN         = (  0,255,255)
MAGENTA      = (255,  0,255)
LIGHT_MAGENTA= (255, 127, 255)
LIGHT_GREEN  = (127,255,127)
YELLOW       = (255,255,  0)
ORANGE       = (255,165,  0)
PURPLE       = (128,  0,128)
LIGHT_GREEN  = (144,238,144)
LIGHT_YELLOW = (255,255,127)
DARK_GREY    = (63,63,63)
DARK_GREEN   = ( 0, 128, 0 )

# Si on veut changer 
PALETTES = [
    [DARK_GREEN, LIGHT_GREEN],
]
PALETTE = PALETTES[IND_PALETTE]
# Numéro de la première ligne basic générée (incrément de 10 ensuite)
BEG_LINE = 9000

def sparse_argv(argv):
    global filename, SPRITE_WIDTH, SPRITE_HEIGHT, NB_FRAMES, BEG_LINE, IND_PALETTE, PALETTE
    for a in argv:
        if a.startswith("--") and "=" in a:
            key, value = a.split("=")
            key = key[2:]
            if key == "filename":
                filename = value
                if os.path.exists(filename+".cfg"):
                    with open(filename+".cfg", "r") as f:
                        for line in f:
                            if line.startswith("#"):
                                continue
                            k, v = line.strip().split("=")
                            if k == "nbframes":
                                NB_FRAMES=int(v)
                            elif k == "begline":
                                BEG_LINE = int(v)
                            elif k == "size":
                                size = v.split("x")
                                SPRITE_WIDTH  = int(size[0])
                                SPRITE_HEIGHT = int(size[1])
            elif key == "nbframes":
                NB_FRAMES = int(value)
            elif key == "size":
                size = value.split("x")
                SPRITE_WIDTH  = int(size[0])
                SPRITE_HEIGHT = int(size[1])
            elif key == "begline":
                BEG_LINE = int(value)
            else:
                raise ValueError("Unknown argument " + key)
        elif a == "--help":
            print(f"Usage : python3 sprite_editor.py --filename=filename --nbframes=NbFrames --size=widthxheight  --begline=lignebasic")
            sys.exit(0)
        elif a.startswith("--"):
            raise ValueError("Argument must be in the form --key=value")
        else:
            raise ValueError("Argument must be in the form --key=value")
    print (f"filename : {filename}, number of frames : {NB_FRAMES}, Size of sprites : {SPRITE_WIDTH}x{SPRITE_HEIGHT}")

if len(sys.argv) > 1 :
    sparse_argv(sys.argv[1:])


class Button:
    """
    Un bouton avec un texte et une fonction à appeler lorsqu'il est cliqué.
    """
    def __init__(self, font, texte : str, rect : pg.Rect, color : tuple, background : tuple, on_click: Callable[[object], None], draw_border : bool = False):
        
        self.text = font.render(texte, False, color, background)
        self.surface = pg.Surface((max(rect.width,self.text.get_width()), max(rect.height,self.text.get_height())))
        pos = (self.surface.get_width()-self.text.get_width())//2,(self.surface.get_height()-self.text.get_height())//2
        self.surface.blit(self.text, pos)
        self.rect = rect
        self.on_click = on_click
        self.is_pointed  = False
        self.is_clicked  = False
        self.is_released = True
        self.draw_border = draw_border

    def draw(self, screen : pg.Surface):
        screen.blit(self.surface, (self.rect.x, self.rect.y))
        if self.is_clicked :
            pg.draw.rect(screen, (0, 255, 0), self.rect, 1)
        elif self.is_pointed :
            pg.draw.rect(screen, (255, 0, 0), self.rect, 1)
        elif self.draw_border :
            pg.draw.rect(screen, WHITE, self.rect, 1)

    def handle_events(self, editor, events : list[pg.event.Event]):
        for event in events :
            if event.type == pg.MOUSEMOTION :
                mouse_pos = pg.mouse.get_pos()
                if self.rect.collidepoint(mouse_pos) :
                    self.is_pointed = True
                else :
                    self.is_pointed = False
                    self.is_clicked = False
                    self.is_released = True
            if event.type == pg.MOUSEBUTTONDOWN :
                mouse_pos = pg.mouse.get_pos()
                if self.rect.collidepoint(mouse_pos) and self.is_released:
                    self.is_clicked  = True
                    self.is_released = False
            if event.type == pg.MOUSEBUTTONUP :
                mouse_pos = pg.mouse.get_pos()
                if self.rect.collidepoint(mouse_pos) :
                    self.is_released = True
            if self.is_clicked and self.is_released:
                self.is_clicked = False
                self.on_click()

class MetaSprite:
    """
    Les données pour un sprite donné dans l'éditeur.
    """
    def __init__(self):
        self.sprites = np.zeros((NB_FRAMES,SPRITE_WIDTH, SPRITE_HEIGHT), dtype=np.byte)
        self.frame   = 0
        self.surface = [pg.Surface((4*SPRITE_WIDTH, 4*SPRITE_HEIGHT)) for i in range(NB_FRAMES)]
        self.zoomed_grid_rect = pg.Rect(70,10,16*SPRITE_WIDTH,16*SPRITE_HEIGHT)
        self.update_surface()
    
    def update_surface(self):
        for i in range(NB_FRAMES):
            self.surface[i].fill((0,0,0))
            for y in range(SPRITE_HEIGHT):
                for x in range(SPRITE_WIDTH):
                    color = PALETTE[self.sprites[i][x,y]]
                    pg.draw.rect(self.surface[i], color, (4*x, 4*y, 4, 4))
        self.zoomed_sprite = pg.transform.scale(self.surface[self.frame], (16*SPRITE_WIDTH, 16*SPRITE_HEIGHT))        
    
    def set_point(self, index, pixel):
        self.sprites[self.frame][pixel[0],pixel[1]] = index
        pg.draw.rect(self.surface[self.frame], PALETTE[index], (4*pixel[0], 4*pixel[1], 4, 4))
        self.zoomed_sprite = pg.transform.scale(self.surface[self.frame], (16*SPRITE_WIDTH, 16*SPRITE_HEIGHT))
    
    def grid_display(self, screen):
        screen.blit(self.zoomed_sprite, (70,10))
        pg.draw.rect(screen, WHITE, self.zoomed_grid_rect, 3)
        for i in range(16,16*SPRITE_WIDTH,16):
            pg.draw.line(screen, WHITE, (i+70,10), (i+70,16*SPRITE_HEIGHT+10), 1)
        for i in range(16, 16*SPRITE_HEIGHT, 16):
            pg.draw.line(screen, WHITE, (70,i+10), (16*SPRITE_WIDTH+70,i+10), 1)
    
    def sprite_display(self,screen, crd = (800,400)):
        y = crd[1]
        for s in self.surface:
            screen.blit(s, (crd[0], y))
            y += (4*SPRITE_HEIGHT+8)
        
    def display_current_frame(self, screen):
        screen.blit(self.surface[self.frame], (150, 400))
        
    def next_frame(self):
        if self.frame < NB_FRAMES-1:
            self.frame += 1
        else:
            self.frame = 0
        self.zoomed_sprite = pg.transform.scale(self.surface[self.frame], (16*SPRITE_WIDTH, 16*SPRITE_HEIGHT))
            
    def previous_frame(self):
        if self.frame > 0:
            self.frame -= 1
        else:
            self.frame = NB_FRAMES-1
        self.zoomed_sprite = pg.transform.scale(self.surface[self.frame], (16*SPRITE_WIDTH, 16*SPRITE_HEIGHT))
    
    def generate_frames(self):
        for i in range(1,NB_FRAMES):
            self.sprites[i] = np.roll(self.sprites[i-1], shift=1, axis=0)
        self.update_surface()
        
    def clear_frame(self):
        self.sprites[self.frame,:,:] = 0
        self.update_surface()
        
    def clear_sprite(self):
        self.sprites[:,:,:] = 0
        self.update_surface()        
        
    def generate_data(self, line : int):
        s = ""
        for f in range(NB_FRAMES):
            s += f"{line} DATA "
            for iy in range(SPRITE_HEIGHT):
                for ix in range(0,SPRITE_WIDTH,4):
                    value = 0
                    for b in range(8):
                        value += self.sprites[f][ix+b,iy] * (2**(7-b))
                    s += f"{value}" + ("," if ix < SPRITE_WIDTH-4 else "")
                s += "," if iy < SPRITE_HEIGHT-1 else ""
            s += "\n"
            line += 10
        return s,line

    def generate_mask_data(self, line : int):
        s = ""
        mask_sprite = (self.sprites[:,:,:] != 0).astype(np.int8)
        for f in range(NB_FRAMES):
            s += f"{line} DATA "
            for iy in range(SPRITE_HEIGHT):
                for ix in range(0,SPRITE_WIDTH,8):
                    value = 0
                    if ix < SPRITE_WIDTH-7:
                        value = mask_sprite[f][ix+7,iy] + 2*mask_sprite[f][ix+6,iy] + 4*mask_sprite[f][ix+5,iy]
                        value += 8*mask_sprite[f][ix+4,iy] + 16*mask_sprite[f][ix+3,iy] + 16*mask_sprite[f][ix+2,iy]
                        value += 64*mask_sprite[f][ix+1,iy] + 128*mask_sprite[f][ix+0,iy]
                    else:
                        value += 16*mask_sprite[f][ix+3,iy] + 16*mask_sprite[f][ix+2,iy]
                        value += 64*mask_sprite[f][ix+1,iy] + 128*mask_sprite[f][ix+0,iy]                        
                    s += f"{value}" + ("," if ix < SPRITE_WIDTH-8 else "")
                s += "," if iy < SPRITE_HEIGHT-1 else ""
            s += "\n"
            line += 10
        return s,line

    
    def generate_asm(self):
        s = ""
        for f in range(NB_FRAMES):
            s += f"\tdb "
            for iy in range(SPRITE_HEIGHT):
                for ix in range(0,SPRITE_WIDTH,8):
                    value = 0
                    for b in range(8):
                        value += self.sprites[f][ix+b,iy] * (2**(7-b))
                    s += f"${hex(value)[2:]:2}"
                    if ix < SPRITE_WIDTH-4:
                        s += ", "
                if iy < SPRITE_HEIGHT-1:
                    s += ', '
                else:
                    s += '\n'
        return s
    
    def generate_bin(self):
        l = []
        for f in range(NB_FRAMES):
            for iy in range(SPRITE_HEIGHT):
                for ix in range(0,SPRITE_WIDTH,8):
                    value = 0
                    for b in range(8):
                        value += self.sprites[f][ix+b,iy] * (2**(7-b))
                    l.append(value)
        return bytearray(l)
    
    def generate_mask_asm(self):
        s = ""
        mask_sprite = (self.sprites[:,:,:] != 0).astype(np.int8)
        for f in range(NB_FRAMES):
            s += f"\tdb "
            for iy in range(SPRITE_HEIGHT):
                for ix in range(0,SPRITE_WIDTH,8):
                    value = 0
                    if ix < SPRITE_WIDTH-7:
                        value = mask_sprite[f][ix+7,iy] + 2*mask_sprite[f][ix+6,iy] + 4*mask_sprite[f][ix+5,iy]
                        value += 8*mask_sprite[f][ix+4,iy] + 16*mask_sprite[f][ix+3,iy] + 16*mask_sprite[f][ix+2,iy]
                        value += 64*mask_sprite[f][ix+1,iy] + 128*mask_sprite[f][ix+0,iy]
                    else:
                        value += 16*mask_sprite[f][ix+3,iy] + 16*mask_sprite[f][ix+2,iy]
                        value += 64*mask_sprite[f][ix+1,iy] + 128*mask_sprite[f][ix+0,iy]                        
                    s += f"${hex(value)[2:]:2}"
                    if ix < SPRITE_WIDTH-8:
                        s += ", "
                if iy < SPRITE_HEIGHT-1:
                    s += ', '
                else:
                    s += '\n'
        return s
        
            
class EditorSprite:
    def __init__(self):
        pg.font.init()
        
        self.font = pg.font.SysFont("monospace", 24)
        self.sprites = []
        self.current_sprite = -1
        self.num_frame = 0
        self.counter_frame = -1
        self.max_counter = 80
        self.index_current_color = 0
        self.buttons = []
        self.buttons.append(Button(self.font, " New sprite ", pg.Rect((800,10),(200,25)), GREEN, DARK_GREY, self.new_sprite))
        self.buttons.append(Button(self.font, "Gen. frames ", pg.Rect((800,40), (200,25)), CYAN, DARK_GREY, self.generage_frames))
        self.buttons.append(Button(self.font, "Load sprites", pg.Rect((800,70), (200,25)), BLUE, DARK_GREY, self.load_sprite))
        self.buttons.append(Button(self.font, "Save sprites", pg.Rect((800,100), (200,25)), YELLOW, DARK_GREY, self.save_sprites))
        self.buttons.append(Button(self.font, "  Gen. Data ", pg.Rect((800,130), (200,25)), GREEN, DARK_GREY, self.generate_data))
        self.buttons.append(Button(self.font, "  Gen. asm " , pg.Rect((800,160), (200,25)), LIGHT_GREEN, DARK_GREY, self.generate_asm))
        self.buttons.append(Button(self.font, "  Gen. bin " , pg.Rect((800,190), (200,25)), LIGHT_GREEN, DARK_GREY, self.generate_bin))
        self.buttons.append(Button(self.font, " Clear frame", pg.Rect((800,220), (200,25)), RED, DARK_GREY, self.clear_frame))
        self.buttons.append(Button(self.font, "Clear sprite", pg.Rect((800,250), (200,25)), YELLOW, RED, self.clear_sprite))

        self.buttons.append(Button(self.font, "   ", pg.Rect((10,10),(50,25)), WHITE, PALETTE[0], self.choose_black, True))
        self.buttons.append(Button(self.font, "   ", pg.Rect((10,40),(50,25)), WHITE, PALETTE[1], self.choose_red, True))

        self.buttons.append(Button(self.font, "→", pg.Rect((600, 610),(25,25)), WHITE, BLACK, self.next_sprite))
        self.buttons.append(Button(self.font, "←", pg.Rect((100, 610),(25,25)), WHITE, BLACK, self.prev_sprite))
        self.buttons.append(Button(self.font, "▶", pg.Rect((400, 610),(25,25)), GREEN, BLACK, self.play_animation))
        self.buttons.append(Button(self.font, "⏹", pg.Rect((300, 610),(25,25)), RED, BLACK, self.stop_animation))
        self.buttons.append(Button(self.font, "▲", pg.Rect((130,610),(25,25)), CYAN, BLACK, self.next_frame))
        self.buttons.append(Button(self.font, "▼", pg.Rect((180,610),(25,25)), MAGENTA, BLACK, self.prev_frame))

    def new_sprite(self):
        self.sprites.append(MetaSprite())
        self.current_sprite = len(self.sprites)-1
        
    def next_sprite(self):
        if self.current_sprite < len(self.sprites)-1:
            self.current_sprite += 1
        else:
            self.current_sprite = 0
            
    def prev_sprite(self):
        if self.current_sprite > 0:
            self.current_sprite -= 1
        else:
            self.current_sprite = len(self.sprites)-1
            
    def next_frame(self):
        self.sprites[self.current_sprite].next_frame()
            
    def prev_frame(self):
        self.sprites[self.current_sprite].previous_frame()
        
    def clear_frame(self):
        self.sprites[self.current_sprite].clear_frame()
        
    def clear_sprite(self):
        self.sprites[self.current_sprite].clear_sprite()
        
    def load_sprite(self):
        self.sprites = []
        with open(filename + ".dat", 'rb') as f:
            l = int.from_bytes(f.read(8), signed=False)
            for i in range(l):
                s = MetaSprite()
                s.sprites = np.load(f)
                s.update_surface()
                self.sprites.append(s)
        self.current_sprite = 0
    
    def save_sprites(self):
        with open(filename + ".dat", 'wb') as f:
            f.write((len(self.sprites)).to_bytes(8,signed=False))
            for sprite in self.sprites:
                np.save(f, sprite.sprites)
                
        if not os.path.exists(filename + ".cfg"):
            with open(filename + ".cfg", 'w') as f:
                lines = [
                    "# Sprite editor configuration\n"
                    f"nbframes={NB_FRAMES}\n",
                    f"begline={BEG_LINE}\n",
                    f"size={SPRITE_WIDTH}x{SPRITE_HEIGHT}\n",
                    f"palette={IND_PALETTE}\n"
                ]
                f.writelines(lines)
        
    def generage_frames(self):
        self.sprites[self.current_sprite].generate_frames()

    def generate_data(self):
        line = BEG_LINE
        with open(filename + ".bas", "w") as f:
            for sprite in self.sprites:
                bas, line = sprite.generate_data(line)
                f.write(bas)
        line += 1000
        with open(filename + "_mask.bas", "w") as f:
            for sprite in self.sprites:
                bas, line = sprite.generate_mask_data(line)
                f.write(bas)
                
    def generate_asm(self):
        with open(filename + ".asm", "w") as f:
            for sprite in self.sprites:
                asm = sprite.generate_asm()
                f.write(asm)
        with open(filename + "_mask.asm", "w") as f:
            for sprite in self.sprites:
                asm = sprite.generate_mask_asm()
                f.write(asm)
                
    def generate_bin(self):
        with open(filename + ".bin", "wb") as f:
            for sprite in self.sprites:
                bin_data = sprite.generate_bin()
                f.write(bin_data)
            
    def play_animation(self):
        self.counter_frame = self.max_counter
    
    def stop_animation(self):
        self.counter_frame = -1
    
    def choose_black(self):
        self.index_current_color = 0

    def choose_red(self):
        self.index_current_color = 1

    def choose_blue(self):
        self.index_current_color = 2
        
    def choose_white(self):
        self.index_current_color  = 3

    def display_screen(self, screen : pg.Surface):
        """
        Affiche l'écran de l'éditeur.
        """
        screen.fill(BLACK)
        for b in self.buttons:
           b.draw(screen)
           
        if self.current_sprite >= 0:
            self.sprites[self.current_sprite].grid_display(screen)
            self.sprites[self.current_sprite].sprite_display(screen)
            self.sprites[self.current_sprite].display_current_frame(screen)
            if self.counter_frame != -1:
                self.counter_frame -= 1
                if self.counter_frame == 0:
                    self.sprites[self.current_sprite].next_frame()
                    self.counter_frame = self.max_counter
            # Affichage des sprites en bas de l'écran :
            x = 10
            y = 700
            for i,s in enumerate(self.sprites):
                s.sprite_display(screen, (x,y))
                if i==self.current_sprite:
                    pg.draw.rect(screen, (255,0,0), (x-2,y-4,4*SPRITE_WIDTH+4,(4*SPRITE_HEIGHT+8)*NB_FRAMES+8), 2)
                x += 4*SPRITE_WIDTH + 4
                if x > screen.get_width() - 4*SPRITE_WIDTH:
                    y += (4*SPRITE_HEIGHT+8)*NB_FRAMES + 8
                    x = 10

    def handle_events(self, events : list[pg.event.Event]):
        for b in self.buttons:
            b.handle_events(self, events)
        if self.current_sprite >= 0:
            for event in events:
                if event.type == pg.MOUSEBUTTONDOWN :
                    mouse_pos = pg.mouse.get_pos()
                    x = (mouse_pos[0]-70)//16
                    y = (mouse_pos[1]-10)//16
                    if self.sprites[self.current_sprite].zoomed_grid_rect.collidepoint(mouse_pos) :
                        self.sprites[self.current_sprite].set_point(self.index_current_color, (x,y))

pg.init()
screen = pg.display.set_mode((1200, 1024))
editor = EditorSprite()
running = True
while running:
    #editor.handle_events()
    editor.display_screen(screen)
    pg.display.flip()
    events = pg.event.get()
    editor.handle_events(events)
    for event in events:
        if event.type == pg.QUIT:
            running = False
pg.quit()
