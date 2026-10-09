from pathlib import Path
r=Path.cwd();o=Path(__file__).resolve().parent
p=r/'commons/maps/SoftBodies_Soft_Body_Deformation/final.md';raw=p.read_bytes();s=raw.decode().replace('\r\n','\n')
a='The cube gives way. Yet it does not become a collection of loose triangles.'
b='The cube gives way. A small arm holds one point at its top; the rest of its surface can move. Yet it does not become a collection of loose triangles.'
assert s.count(a)==1;s=s.replace(a,b)
s=s.replace('What can the remaining links hold on their own?','What can the linked surface keep when inflation no longer helps it?')
s=s.replace('First we need to see how a surface changes when some of its points are required to stay.','Here we changed the response of a body while one point remained held. In the next room we change which points must stay.')
if b'\r\n' in raw:s=s.replace('\n','\r\n')
p.write_bytes(s.encode())
p=r/'commons/maps/SoftBodies_Soft_Body_Deformation/technical.md';raw=p.read_bytes();s=raw.decode().replace('\r\n','\n')
s=s.replace('The cube gives way. Yet it does not become a collection of loose triangles.',b)
note='''The opening hall opts into `jelly_cube:180:1.0#anchor:crown`. One vertex nearest the centre of the top face is pinned. A small brass stem and open stand expose that attachment; there is no plate underneath the deforming surface. The local control rack is lowered and brought forward to keep it clear of the body. The default `anchor:free` retains the original pedestal and unpinned body in other placements. Anchor is a placement setting, read before construction, not a new live control. Changing the existing coefficients does not rebuild the body or release the pin.

The unpinned cube left its original support during a native control sequence. Several tray trials also failed to retain it; those diagnostics are preserved in the opening review. The crown attachment establishes an explicit boundary condition for this lesson. It does not certify free soft-body contact with a tray or solve that separate collision problem.

'''
s=s.replace('Floor provenance:',note+'Floor provenance:')
if b'\r\n' in raw:s=s.replace('\n','\r\n')
p.write_bytes(s.encode())
p=o/'publish.py';s=p.read_text()
s=s.replace('The cube receives a physical tray after the first capture revealed it leaving its small pedestal.','The cube now hangs from one visible held point after the first capture revealed it leaving its small pedestal. The cloth lets the reader change the held set.')
s=s.replace('The body and its receiver','One point stays. The surface yields.')
s=s.replace('This hall now uses a receiving tray. The cube remains unpinned. Wider camera includes the new support.','This hall now holds one upper point. The open stand and brass stem expose the attachment. Wider camera includes the revised support.')
p.write_bytes(s.encode())
