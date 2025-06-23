#! C:/BCI2000.64/prog/BCI2000Shell
@cls & C:\BCI2000.64\prog\BCI2000Shell %0 %* #! && exit /b 0 || exit /b 1\n
#######################################################################################
## $Id: StimulusPresentation_SignalGenerator.bat 6137 2020-07-30 13:50:39Z mellinger $
## Description: BCI2000 startup Operator module script. For an Operator scripting
##   reference, see
##   http://doc.bci2000.org/index/User_Reference:Operator_Module_Scripting
##
## $BEGIN_BCI2000_LICENSE$
##
## This file is part of BCI2000, a platform for real-time bio-signal research.
## [ Copyright (C) 2000-2020: BCI2000 team and many external contributors ]
##
## BCI2000 is free software: you can redistribute it and/or modify it under the
## terms of the GNU General Public License as published by the Free Software
## Foundation, either version 3 of the License, or (at your option) any later
## version.
##
## BCI2000 is distributed in the hope that it will be useful, but
##                         WITHOUT ANY WARRANTY
## - without even the implied warranty of MERCHANTABILITY or FITNESS FOR
## A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License along with
## this program.  If not, see <http://www.gnu.org/licenses/>.
##
## $END_BCI2000_LICENSE$
#######################################################################################
Change directory $BCI2000LAUNCHDIR
Show window; Set title ${Extract file base $0}
Reset system
##SANTIAdd event TriggerFromProcessing 1 0
Startup system localhost


Start executable SignalGenerator --local --LogKeyboard=1 --LogMouse=1
Start executable P3SignalProcessing --local
Start executable StimulusPresentation --local

Wait for Connected

Load parameterfile "../parms/parms_TFG_externalTrigger/parms_application_2stimuli.prm"
Load parameterfile "../parms/parms_TFG_externalTrigger/additionalSettings_MouseKeys.prm"

ADD WATCH StimulusCodeCop StimulusTypeCop PhaseInSequenceCop StimulusCodeRes SelectedStimulus AT localhost:12345