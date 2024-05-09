package com.c104.seolo.domain.report.controller;

import com.c104.seolo.domain.report.dto.ReportDto;
import com.c104.seolo.domain.report.dto.response.ReportsReponse;
import com.c104.seolo.domain.report.service.ReportService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.annotation.Secured;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/reports")
@RequiredArgsConstructor
public class ReportController {
    private final ReportService reportService;

    @ResponseStatus(HttpStatus.OK)
    @Secured("ROLE_MANAGER")
    @GetMapping
    public ReportsReponse getAllReports() {
        return reportService.getAllReports();
    }

    @Secured("ROLE_MANAGER")
    @GetMapping("/{reportId}")
    public ReportDto getReport(@PathVariable Long reportId) {
        return reportService.getReport(reportId);
    }
}