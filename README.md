Make minicomputer (HITAC10) with #FPGA

<Tape reader function>
1. This unit has a tape reader function attached to the HITAC10 main unit.
2. The tape reader function operates in response to a request from the main unit.
3. The connection with the tape reader is simple (unique) connection.
4. OML and MASS are continuously stored in the memory (12KB) as tape data.

<Execution step>
1. Immediately after reset, this unit transfers the IPL to the core memory unit and executes the IPL from PC = 2.
2.IPL requests tape reader to read tape (OML).
3. The tape reader reads the tape data and sends it to the main unit.
4.When reading of OML is completed, reading of extension mechanism software is started.
5. When reading is completed, jump to PC = 0x20 and start reading MASS tape.
�� This part is a manual operation originally, a function not found in HITAC10.
�� 6, After reading the first block of the MASS tape, jump to PC = 0x180.
7. Looping waiting for an interrupt from the tape reader.

See below for details
[[Celebration] HITAC10 50th anniversary] (https://qiita.com/hi631/items/7956a119cf96ed01b6d4)

<BR>

�e�o�f�`�Ń~�j�R���i�g�h�s�`�b�P�O�j�����

�@<�e�[�v���[�_�[�@�\>
�@1.�{�@��HITAC10�{�̂ɕt�����āA�e�[�v���[�_�[�@�\��L���Ă���B
�@2.�{�̂���̗v���ɉ����āA�e�[�v���[�_�[�@�\�����삷��B
�@3.�e�[�v���[�_�[�Ƃ̐ڑ��͊Ȉ�(�Ǝ�)�ڑ��B
�@4.�e�[�v�f�[�^�[�Ƃ��āA������(12KB)��OML,MASS��A�����Ċi�[���Ă���B

�@<���s�X�e�b�v>
�@1.�{�@�̓��Z�b�g����AIPL���R�A���������ɓ]�����APC=2�Ԓn����IPL�����s����B
�@2.IPL�̓e�[�v���[�_�[�ɁA�e�[�v(OML)�̓ǂݍ��݂�v������B
�@3.�e�[�v���[�_�[�̓e�[�v�f�[�^��ǂݎ��A�{�̂ɑ��o����B
�@4.OML�̓ǂݎ�肪��������ƁA�g���@�\�\�t�g�̓ǂݎ����n�߂�B
�@5.�ǂݎ�肪��������ƁAPC=0x20�Ԓn�ɃW�����v���AMASS�e�[�v�̓ǂݎ����J�n����B
�@�@�����̕����͖{���͎蓮����ł���AHITAC10�ɂ͖����@�\�B
�@6,MASS�e�[�v�̐擪�u���b�N��ǂݎ���APC=0x180�ɃW�����v�B
�@7.�e�[�v���[�_���̊��荞�ݑ҂��Ń��[�v���Ă���B

�ڂ����͉��L���Q��
[�m�j�n�g�h�s�`�b�P�O ���a�T�O���N](https://qiita.com/hi631/items/7956a119cf96ed01b6d4)
