// U2S_SettingsDlg.h : header file
//

#if !defined(AFX_U2S_SETTINGSDLG_H__92205FBD_6D9B_4E19_8E19_8EE327ED8526__INCLUDED_)
#define AFX_U2S_SETTINGSDLG_H__92205FBD_6D9B_4E19_8E19_8EE327ED8526__INCLUDED_

#if _MSC_VER >= 1000
#pragma once
#endif // _MSC_VER >= 1000

#include "U2S.h"

/////////////////////////////////////////////////////////////////////////////
// CU2S_SettingsDlg dialog

class CU2S_SettingsDlg : public CDialog
{
// Construction
public:
	CU2S_SettingsDlg(CWnd* pParent = NULL);	// standard constructor

// Dialog Data
	//{{AFX_DATA(CU2S_SettingsDlg)
	enum { IDD = IDD_U2S_SETTINGS_DIALOG };
	CComboBox	m_CMode;
	CComboBox	m_CISP;
	CString	m_Msg;
	//}}AFX_DATA

	// ClassWizard generated virtual function overrides
	//{{AFX_VIRTUAL(CU2S_SettingsDlg)
	public:
	virtual BOOL DestroyWindow();
	protected:
	virtual void DoDataExchange(CDataExchange* pDX);	// DDX/DDV support
	//}}AFX_VIRTUAL

// Implementation
protected:
	HICON m_hIcon;
	U2S u2s;

	// Generated message map functions
	//{{AFX_MSG(CU2S_SettingsDlg)
	virtual BOOL OnInitDialog();
	afx_msg void OnSysCommand(UINT nID, LPARAM lParam);
	afx_msg void OnPaint();
	afx_msg HCURSOR OnQueryDragIcon();
	virtual void OnOK();
	afx_msg void OnBRefresh();
	afx_msg void OnBDefaults();
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};

//{{AFX_INSERT_LOCATION}}
// Microsoft Developer Studio will insert additional declarations immediately before the previous line.

#endif // !defined(AFX_U2S_SETTINGSDLG_H__92205FBD_6D9B_4E19_8E19_8EE327ED8526__INCLUDED_)
