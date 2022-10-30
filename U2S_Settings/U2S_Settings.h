// U2S_Settings.h : main header file for the U2S_SETTINGS application
//

#if !defined(AFX_U2S_SETTINGS_H__217E4B6F_4BF8_49F3_83AD_BC8C70C38751__INCLUDED_)
#define AFX_U2S_SETTINGS_H__217E4B6F_4BF8_49F3_83AD_BC8C70C38751__INCLUDED_

#if _MSC_VER >= 1000
#pragma once
#endif // _MSC_VER >= 1000

#ifndef __AFXWIN_H__
	#error include 'stdafx.h' before including this file for PCH
#endif

#include "resource.h"		// main symbols

/////////////////////////////////////////////////////////////////////////////
// CU2S_SettingsApp:
// See U2S_Settings.cpp for the implementation of this class
//

class CU2S_SettingsApp : public CWinApp
{
public:
	CU2S_SettingsApp();

// Overrides
	// ClassWizard generated virtual function overrides
	//{{AFX_VIRTUAL(CU2S_SettingsApp)
	public:
	virtual BOOL InitInstance();
	//}}AFX_VIRTUAL

// Implementation

	//{{AFX_MSG(CU2S_SettingsApp)
		// NOTE - the ClassWizard will add and remove member functions here.
		//    DO NOT EDIT what you see in these blocks of generated code !
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};


/////////////////////////////////////////////////////////////////////////////

//{{AFX_INSERT_LOCATION}}
// Microsoft Developer Studio will insert additional declarations immediately before the previous line.

#endif // !defined(AFX_U2S_SETTINGS_H__217E4B6F_4BF8_49F3_83AD_BC8C70C38751__INCLUDED_)
