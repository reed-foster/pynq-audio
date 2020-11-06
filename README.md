# pynq-audio

generate bitstream
`write_bd_tcl <filename>` to export the board tcl file

```python
from pynq import Overlay
ol = Overlay("/home/xilinx/juypter_notebooks/audio_processing/overlay.bit")
ol.download()


```
