"""
OneLab - Copyright (C) 2011-2013 ULg-UCL

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use, copy,
modify, merge, publish, distribute, and/or sell copies of the
Software, and to permit persons to whom the Software is furnished
to do so, provided that the above copyright notice(s) and this
permission notice appear in all copies of the Software and that
both the above copyright notice(s) and this permission notice
appear in supporting documentation.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT OF THIRD PARTY RIGHTS. IN NO EVENT SHALL THE
COPYRIGHT HOLDER OR HOLDERS INCLUDED IN THIS NOTICE BE LIABLE FOR
ANY CLAIM, OR ANY SPECIAL INDIRECT OR CONSEQUENTIAL DAMAGES, OR ANY
DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS,
WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS
ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE
OF THIS SOFTWARE.

Please report all bugs and problems to the public mailing list
<gmsh@geuz.org>.
"""

import socket, struct, os, sys
_VERSION = '1.05'

def file_exist(filename):
  try:
    with open(filename) as f:
      return True
  except IOError:
    return False

def path(ref,inp):
  if inp[0] == '/' or inp[0] == '\\' or (len(inp) > 2 and inp[1] == '\:'):
     return inp # do nothing, inp is an absolute path
  else: # append inp to the path of the reference file
     return os.path.dirname(ref) + os.sep + inp

class _parameter() :
  _membersbase = [
    ('name', 'string'), ('label', 'string', ''), ('help', 'string', ''),
    ('neverChanged', 'int', 0), ('changed', 'int', 1), ('visible', 'int', 1),
    ('readOnly', 'int', 0), ('attributes', ('dict', 'string', 'string'), {}),
    ('clients', ('list', 'string'), [])
  ]
  _members = {
    'string' : _membersbase + [
      ('value', 'string',''), ('kind', 'string', 'generic'), ('choices', ('list', 'string'), [])
    ],
    'number' : _membersbase + [
      ('value', 'float',0),
      ('min', 'float', -sys.float_info.max), ('max', 'float', sys.float_info.max),
      ('step', 'float', 0.), ('index', 'int', -1), ('choices', ('list', 'float'), []),
      ('labels', ('dict', 'float', 'string'), {})
    ]
  }

  def __init__(self, type, **values) :
    self.type = type
    for i in _parameter._members[self.type] :
      setattr(self, i[0], values[i[0]] if i[0] in values else i[2])

  def tochar(self) :
    def tocharitem(l, t, v) :
      if t=='string' : l.append(v)
      elif t =='int': l.append(str(v))
      elif t=='float' : l.append('%.16g' % v)
      elif t[0]=='list' : 
        l.append(str(len(v)))
        for i in v : tocharitem(l, t[1], i)
      elif t[0]=='dict' :
        l.append(str(len(v)))
        for i, j in v.items() :
          tocharitem(l, t[1], i)
          tocharitem(l, t[2], j)
    msg = [_VERSION, self.type]
    for i in _parameter._members[self.type] :
      tocharitem(msg, i[1], getattr(self, i[0]))
    return '\0'.join(msg)

  def fromchar(self, msg) :
    def fromcharitem(l, t) :
      if t=='string' : return l.pop()
      elif t =='int': return int(l.pop())
      elif t=='float' : return float(l.pop())
      elif t[0]=='list' : return [fromcharitem(l, t[1]) for i in range(int(l.pop()))]
      elif t[0]=='dict' : return dict([(fromcharitem(l, t[1]),fromcharitem(l, t[2])) for i in range(int(l.pop()))])
    l = msg.split('\0')
    l.reverse()
    if l.pop() != _VERSION :
      print('onelab version mismatch')
    if l.pop() != self.type :
      print('onelab parameter type mismatch')
    for p in  _parameter._members[self.type]:
      setattr(self, p[0], fromcharitem(l, p[1]))
    return self

  def modify(self, **param) :
    for i in _parameter._members[self.type] :
      if i[0] in param :
        setattr(self, i[0], param[i[0]]) #NB: no else statement => update


class client :
  _GMSH_START = 1
  _GMSH_STOP = 2
  _GMSH_INFO = 10
  _GMSH_WARNING = 11
  _GMSH_ERROR = 12
  _GMSH_PROGRESS = 13
  _GMSH_MERGE_FILE = 20
  _GMSH_PARSE_STRING = 21
  _GMSH_PARAMETER = 23
  _GMSH_PARAMETER_QUERY = 24
  _GMSH_CONNECT = 27
  _GMSH_OLPARSE = 28
  _GMSH_PARAMETER_NOT_FOUND = 29
  _GMSH_PARAMETER_CLEAR = 31
  _GMSH_PARAMETER_UPDATE = 32

  def _receive(self) :
    def buffered_receive(l) :
      msg = b''
      while len(msg) < l:
        chunk = self.socket.recv(l - len(msg))
        if not chunk :
          RuntimeError('onelab socket closed')
        msg += chunk
      return msg
    msg = buffered_receive(struct.calcsize('ii'))
    t, l = struct.unpack('ii', msg)
    msg = buffered_receive(l).decode('utf-8')
    if t == self._GMSH_INFO :
      print('onelab info : %s' % msg)
    return t, msg

  def _send(self, t, msg) :
    m = msg.encode('utf-8')
    try:
      if self.socket.send(struct.pack('ii%is' %len(m), t, len(m), m)) == 0 :
        RuntimeError('onelab socket closed')
    except socket.error:
      self.socket.close()
      self._createSocket()
      self.socket.send(struct.pack('ii%is' %len(m), t, len(m), m))

  def _define_parameter(self, param) :
    if not self.socket :
      return param.value
    self._send(self._GMSH_PARAMETER_QUERY, param.tochar())
    (t, msg) = self._receive() 
    if t == self._GMSH_PARAMETER :
      self._send(self._GMSH_PARAMETER_UPDATE, param.tochar()) #enrich a previous decl.
      return param.fromchar(msg).value # use value from server
    elif t == self._GMSH_PARAMETER_NOT_FOUND :
      self._send(self._GMSH_PARAMETER, param.tochar()) #declaration
      return param.value
    
  def defineNumber(self, name, **param):
    if 'labels' in param :
      param["choices"] = param["labels"].keys()
    p = _parameter('number', name=name, **param)
    if 'value' not in param : #make the parameter readOnly
      p.readOnly = 1
      p.attributes={'Highlight':'AliceBlue'}
    value = self._define_parameter(p)
    return value

  def defineString(self, name, **param):
    p = _parameter('string', name=name, **param)
    if 'value' not in param : #make the parameter readOnly
      p.readOnly = 1
      p.attributes={'Highlight':'AliceBlue'}
    self._define_parameter(p)
    return p.value
  
  def setNumber(self, name, **param):
    if not self.socket :
      return
    p = _parameter('number', name=name)
    self._send(self._GMSH_PARAMETER_QUERY, p.tochar())
    (t, msg) = self._receive() 
    if t == self._GMSH_PARAMETER :
      p.fromchar(msg).modify(**param)
    elif t == self._GMSH_PARAMETER_NOT_FOUND :
      p.modify(**param)
    self._send(self._GMSH_PARAMETER, p.tochar())

  def setString(self, name, **param):
    if not self.socket :
      return
    p = _parameter('string', name=name)
    self._send(self._GMSH_PARAMETER_QUERY, p.tochar())
    (t, msg) = self._receive() 
    if t == self._GMSH_PARAMETER : #modify an existing parameter
      p.fromchar(msg).modify(**param)
    elif t == self._GMSH_PARAMETER_NOT_FOUND : #create a new parameter
      p.modify(**param)
    p.readOnly = 1
    p.attributes={'Highlight':'AliceBlue'}   
    self._send(self._GMSH_PARAMETER, p.tochar())

  def addNumberChoice(self, name, value):
    if not self.socket :
      return
    p = _parameter('number', name=name)
    self._send(self._GMSH_PARAMETER_QUERY, p.tochar())
    (t, msg) = self._receive() 
    if t == self._GMSH_PARAMETER :
      p.fromchar(msg).choices.append(value)
    elif t == self._GMSH_PARAMETER_NOT_FOUND :
      print ('Unknown parameter %s' %(param.name))
    self._send(self._GMSH_PARAMETER, p.tochar())

  def _get_parameter(self, param, warn_if_not_found=True) :
    if not self.socket :
      return
    self._send(self._GMSH_PARAMETER_QUERY, param.tochar())
    (t, msg) = self._receive() 
    if t == self._GMSH_PARAMETER :
      param.fromchar(msg)
    elif t == self._GMSH_PARAMETER_NOT_FOUND and warn_if_not_found :
      print ('Unknown parameter %s' %(param.name))

  def getNumber(self, name, warn_if_not_found=True):
    param = _parameter('number', name=name)
    self._get_parameter(param, warn_if_not_found)
    return param.value

  def getString(self, name, warn_if_not_found=True):
    param = _parameter('string', name=name)
    self._get_parameter(param, warn_if_not_found)
    return param.value

  def show(self, name) :
    if not self.socket :
      return
    param = _parameter('number', name=name)
    self._send(self._GMSH_PARAMETER_QUERY, param.tochar())
    (t, msg) = self._receive() 
    if t == self._GMSH_PARAMETER :
      print (msg)
    elif t == self._GMSH_PARAMETER_NOT_FOUND :
      print ('Unknown parameter %s' %(name))

  def openGeometry(self, filename) :
    if not self.socket or not filename :
      return
    #if self.action == 'compute' and self.getString('Gmsh/MergedGeo', False) == filename :
    if self.getString('Gmsh/MergedGeo', False) == filename :
      return
    else :
      self.setString('Gmsh/MergedGeo', value=filename)
#    if filename[0] != '/' :
#      filename = os.getcwd() + "/" + filename
    self._send(self._GMSH_MERGE_FILE, filename)

  def mesh(self, filename) :
    if not self.socket :
      return
    if filename[0] != '/' :
      filename = os.getcwd() + "/" + filename
    self._send(self._GMSH_PARSE_STRING, 'Mesh 3; Save "' + filename + '";')

  def sendCommand(self, command) :
    if not self.socket :
      return
    self._send(self._GMSH_PARSE_STRING, command + ' ;')
    
  def mergeFile(self, filename) :
    if not self.socket :
      return
    #self._send(self._GMSH_PARSE_STRING, 'Merge "' + filename + '";')
    self._send(self._GMSH_MERGE_FILE,filename)

  def sendInfo(self, msg) :
    if not self.socket :
      print (msg)
      return
    self._send(self._GMSH_INFO, msg)

  def sendWarning(self, msg) :
    if not self.socket :
      print (msg)
      return
    self._send(self._GMSH_WARNING, msg)

  def sendError(self, msg) :
    if not self.socket :
      print (msg)
      return
    self._send(self._GMSH_ERROR, msg)

  def preProcess(self, filename) :
    if not self.socket :
      return
    self._send(self._GMSH_OLPARSE, filename)
    (t, msg) = self._receive() 
    if t == self._GMSH_OLPARSE :
      print (msg)
        
  def _createSocket(self) :
    addr = self.addr
    if '/' in addr or '\\' in addr or ':' not in addr :
      self.socket = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
      self.socket.connect(addr)
    else :
      self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
      s = addr.split(':')
      self.socket.connect((s[0], int(s[1])))

  def _wait_on_subclients(self):
    if not self.socket :
      return
    while self.NumSubClients > 0:
      (t, msg) = self._receive() 
      if t == self._GMSH_STOP :
        self.NumSubClients -= 1

  def run(self, name, command, arguments):
    if not self.socket :
      return
    if self.action == "check":
      msg = [name, command]
    else:
      msg = [name, command + ' ' + arguments]
    self._send(self._GMSH_CONNECT, '\0'.join(msg))
    self.NumSubClients +=1
    self._wait_on_subclients() # makes the subclient blocking

  def __init__(self):
    self.socket = None
    self.name = ""
    self.addr = ""
    self.NumSubClients = 0
    for i, v in enumerate(sys.argv) :
      if v == '-onelab':
        self.name = sys.argv[i + 1]
        self.addr = sys.argv[i + 2]
        self._createSocket()
        self._send(self._GMSH_START, str(os.getpid()))
    self.action = self.getString(self.name + '/Action')
    self.setNumber('IsPyMetamodel',value=1,visible=0)
    if self.action == "initialize": exit(0)

  def finalize(self):
    # code aster python interpreter does not call the destructor at exit, it is
    # necessary to call finalize() epxlicitely
    if self.socket :
      self._wait_on_subclients()
      self._send(self._GMSH_STOP, 'Goodbye!')
      self.socket.close()
      self.socket = None
    
  def __del__(self):
    self.finalize()
