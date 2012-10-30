; docformat = 'rst'

;+
; Results for tests, test cases, and test suites are reported to the test 
; runner. The `MGutGUIRunner` displays the results in an interactive GUI.
;
; :Private:
;-


;+
; Event handler for GUI runner.
;
; :Params:
;    event : in, required, type=event structure
;       event structure for any event generated by GUI runner
;-
pro mgutguirunner_event, event
  compile_opt strictarr

  widget_control, event.top, get_uvalue=widget
  widget->_eventHandler, event
end


;+
; Widget cleanup routine.
;
; :Params:
;    tlb : in, required, type=long
;       top-level widget identifier
;-
pro mgutguirunner_cleanup, tlb
  compile_opt strictarr
  
  widget_control, tlb, get_uvalue=widget
  widget->_cleanupWidgets
end


;+
; Report a test suite has begun.
; 
; :Params:
;    testsuite : in, required, type=string
;       name of test suite
;
; :Keywords:
;    ntestcases : in, required, type=integer
;       number of test suites/cases contained by the test suite
;    ntests : in, required, type=integer
;       number of tests contained in the hierarchy below this test suite
;    level : in, required, type=level
;       level of test suite
;-
pro mgutguirunner::reportTestSuiteStart, testsuite, $
                                         ntestcases=ntestcases, $
                                         ntests=ntests, $
                                         level=level
  compile_opt strictarr

  indent = level eq 0 ? '' : string(bytarr(level * self.indent) + self.space)
  self->_print, indent + '"' + testsuite $
                  + '" test suite starting (' $
                  + strtrim(ntestcases, 2) + ' test suite' $
                  + (ntestcases eq 1 ? '' : 's') $          
                  + '/case' $
                  + (ntestcases eq 1 ? '' : 's') $
                  + ', ' $
                  + strtrim(ntests, 2) + ' test' + (ntests eq 1 ? '' : 's') $
                  + ')'
end


;+
; Report the results of a test suite.
;
; :Keywords:
;    npass : in, required, type=integer 
;       number of passing tests contained in the hierarchy below the test 
;       suite
;    nfail : in, required, type=integer
;       number of failing tests contained in the hierarchy below the test 
;       suite
;    nskip : in, required, type=integer
;       number of skipped tests contained in the hierarchy below the test 
;       suite
;    level : in, required, type=integer
;       level of test suite
;-
pro mgutguirunner::reportTestSuiteResult, npass=npass, nfail=nfail, $
                                          nskip=nskip, level=level
  compile_opt strictarr

  format = '(%"%sResults: %d / %d tests passed, %d skipped")'
  indent = level eq 0 ? '' : string(bytarr(level * self.indent) + self.space)
  self->_print, string(indent, npass, npass + nfail, nskip, format=format)
end


;+
; Report a test case has begun.
; 
; :Params:
;    testcase : in, required, type=string
;       name of test case
;
; :Keywords:
;    ntests : in, required, type=integer
;       number of tests contained in this test case
;    level : in, required, type=level
;       level of test case
;-
pro mgutguirunner::reportTestCaseStart, testcase, ntests=ntests, level=level
  compile_opt strictarr

  indent = string(bytarr(level * self.indent) + self.space)
  self->_print, indent + '"' + testcase + '" test case starting' $
                  + ' (' + strtrim(ntests, 2) $
                  + ' test' + (ntests eq 1 ? '' : 's') + ')'
end


;+
; Report the results of a test case.
;
; :Keywords:
;    npass : in, required, type=integer
;       number of passing tests
;    nfail : in, required, type=integer
;       number of failing tests
;    nskip : in, required, type=integer
;       number of skipped tests
;    level : in, required, type=integer
;       level of test case
;-
pro mgutguirunner::reportTestCaseResult, npass=npass, nfail=nfail, $
                                         nskip=nskip, level=level
  compile_opt strictarr

  format = '(%"%sResults: %d / %d tests passed, %d skipped")'
  indent = string(bytarr(level * self.indent) + self.space)
  self->_print, string(indent, npass, npass + nfail, nskip, format=format)
end


;+
; Report the start of single test.
; 
; :Params:
;    testname : in, required, type=string
;       name of test
;
; :Keywords:
;    level : in, required, type=integer
;       level of test case
;-
pro mgutguirunner::reportTestStart, testname, level=level
  compile_opt strictarr

  indent = string(bytarr((level + 1L) * self.indent) + self.space)
  self->_print, indent + testname + ': ', /continued
end


;+
; Report the result of a single test.
; 
; :Params:
;    msg : in, required, type=string
;       message to display when test fails
; 
; :Keywords:
;    passed : in, required, type=boolean
;       whether the test passed
;    output : in, optional, type=string
;       output from the test run
;    time : in, required, type=float
;       time for the test to run
;    level : in, required, type=integer
;       level of test case
;    skipped : in, required, type=boolean
;       indicates whether the test should be counted in the results
;-
pro mgutguirunner::reportTestResult, msg, passed=passed, $
                                     output=output, time=time, $
                                     skipped=skipped, level=level
  compile_opt strictarr

  if (skipped) then begin
    self->_print, 'invalid' + (msg eq '' ? '' : ' "' + msg + '"'), /continued
  endif else if (passed) then begin
    self->_print, 'passed', /continued
  endif else begin
    self->_print, 'failed' + (msg eq '' ? '' : ' "' + msg + '"'), /continued
  endelse

  if (size(output, /type) eq 7 && output ne '') then begin
    self->_print, self.logLun, ' [' + output + ']', /continued
  endif
  self->_print, string(time, format='(%" (%f seconds)")')
end


;+
; Routine to display the results of a test.
;
; :Params:
;    text : in, required, type=string
;       message to display
;
; :Keywords:
;    continued : in, optional, type=boolean
;       set to indicate that the text is not finished
;    _extra : in, optional, type=keywords
;       extra keywords present for compatibility with other runners
;-
pro mgutguirunner::_print, text, continued=continued, _extra=e
  compile_opt strictarr
  
  if (self.continued) then begin
    widget_control, self.text, get_value=fullText
    fullText[n_elements(fullText) - 1L] += text
    widget_control, self.text, set_value=fullText
  endif else begin
    widget_control, self.text, set_value=text, append=~self.cleared
    self.cleared = 0B
  endelse
  
  self.continued = keyword_set(continued)
end


;+
; Free resources.
;-
pro mgutguirunner::cleanup
  compile_opt strictarr

  obj_destroy, [self.suite, self.parent]
  self->mguttestrunner::cleanup
end


;+
; Creates the user-interface for the GUI test runner.
;-
pro mgutguirunner::_createWidgets
  compile_opt strictarr
  
  self.tlb = widget_base(title='mgunit', /column, uvalue=self, uname='tlb', $
                         /tlb_size_events)
  
  self.toolbar = widget_base(self.tlb, /toolbar, space=0)
  
  resourcedir = ['resource', 'bitmaps']
  rerun = widget_button(self.toolbar, uname='rerun', $
                        value=filepath('redo.bmp', subdir=resourcedir), $
                        /bitmap)
                        
  self.text = widget_text(self.tlb, xsize=100, ysize=20, /scroll)
end


;+
; Realizes the user-interface for the GUI test runner.
;-
pro mgutguirunner::_realizeWidgets
  compile_opt strictarr
  
  widget_control, self.tlb, /realize
end


;+
; Starts up XMANAGER.
;-
pro mgutguirunner::_startXManager
  compile_opt strictarr
  
  xmanager, 'MGutGuiRunner', self.tlb, /no_block, $
            event_handler='mgutguirunner_event', $
            cleanup='mgutguirunner_cleanup'
end


;+
; Handles all events from the GUI test runner.
; 
; :Params:
;    event : in, required, type=structure
;       event structure from any widget generating events in the GUI test 
;       runner
;-
pro mgutguirunner::_eventHandler, event
  compile_opt strictarr

  uname = widget_info(event.id, /uname)
  
  case uname of
    'tlb': begin
        tlbG = widget_info(event.top, /geometry)
        toolbarG = widget_info(self.toolbar, /geometry)
        
        xsize = event.x - 2 * tlbG.xpad
        ysize = event.y - 2 * tlbG.ypad - tlbG.space - toolbarG.scr_ysize
        
        widget_control, self.text, scr_xsize=xsize, scr_ysize=ysize
      end
    'rerun': begin
        ; clear text widget
        widget_control, self.text, set_value=''
        self.cleared = 1B
        
        ; rerun tests
        self.suite->recompileTestCases
        self.suite->run
      end
    else:
  endcase
end


;+
; Widget cleanup routine.
;-
pro mgutguirunner::_cleanupWidgets
  compile_opt strictarr
  
  obj_destroy, self
end


;+
; Initialize the test runner.
;
; :Returns: 
;    1 for success, 0 for failure
;-
function mgutguirunner::init, filename=filename, color=color, _extra=e
  compile_opt strictarr

  if (~self->mguttestrunner::init(_extra=e)) then return, 0B

  self->_createWidgets
  self->_realizeWidgets
  self->_startXManager

  self.cleared = 0B
  self.indent = 3L
  self.space = (byte(' '))[0]
  
  return, 1B
end


;+
; Define member variables.
;
; :Fields:
;    tlb
;       top-level base of GUI
;    toolbar
;       base widget containing toolbar items
;    text
;       text widget displaying results
;    continued
;    cleared
;    indent
;    space
;-
pro mgutguirunner__define
  compile_opt strictarr

  define = { mgutguirunner, inherits MGutTestRunner, $
             tlb: 0L, $
             toolbar: 0L, $
             text: 0L, $
             continued: 0B, $
             cleared: 0B, $
             indent: 0L, $
             space: '' $
           }
end
