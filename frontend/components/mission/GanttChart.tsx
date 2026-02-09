/**
 * GanttChart Component
 * Custom Gantt chart for mission milestone visualization
 */

import { useMemo } from 'react';
import { Milestone, MilestoneStatus, getMilestoneStatusColor } from '@/types/milestone.js';
import { format, differenceInDays, addDays } from 'date-fns';
import { fr } from 'date-fns/locale';

export interface GanttChartProps {
  milestones: Milestone[];
  startDate: Date;
  endDate: Date;
}

interface GanttBar {
  milestone: Milestone;
  left: number; // Percentage from left
  width: number; // Percentage width
  color: string;
  isOverdue: boolean;
}

export function GanttChart({ milestones, startDate, endDate }: GanttChartProps) {
  // Calculate total project duration in days
  const totalDays = differenceInDays(endDate, startDate);
  const today = new Date();

  // Generate timeline marks (weeks)
  const timelineMarks = useMemo(() => {
    const marks: { date: Date; label: string; position: number }[] = [];
    let currentDate = new Date(startDate);

    while (currentDate <= endDate) {
      const daysFromStart = differenceInDays(currentDate, startDate);
      const position = (daysFromStart / totalDays) * 100;

      marks.push({
        date: currentDate,
        label: format(currentDate, 'd MMM', { locale: fr }),
        position,
      });

      currentDate = addDays(currentDate, 7); // Weekly marks
    }

    return marks;
  }, [startDate, endDate, totalDays]);

  // Calculate today's position
  const todayPosition = useMemo(() => {
    if (today < startDate) return 0;
    if (today > endDate) return 100;

    const daysFromStart = differenceInDays(today, startDate);
    return (daysFromStart / totalDays) * 100;
  }, [today, startDate, endDate, totalDays]);

  // Calculate Gantt bars for milestones
  const ganttBars: GanttBar[] = useMemo(() => {
    // Sort milestones by order
    const sorted = [...milestones].sort((a, b) => a.order - b.order);

    return sorted.map((milestone) => {
      // Estimate start date based on order
      // Simple estimation: divide project duration equally
      const milestoneIndex = sorted.indexOf(milestone);
      const estimatedStartDays = (totalDays / sorted.length) * milestoneIndex;
      const estimatedStart = addDays(startDate, estimatedStartDays);

      // Calculate bar position
      const barStartDays = differenceInDays(estimatedStart, startDate);
      const barEndDays = differenceInDays(milestone.dueDate, startDate);

      const left = Math.max(0, (barStartDays / totalDays) * 100);
      const width = Math.max(
        2,
        Math.min(100 - left, ((barEndDays - barStartDays) / totalDays) * 100)
      );

      // Determine color based on status
      let color = '';
      switch (milestone.status) {
        case MilestoneStatus.Approved:
          color = 'bg-green-500 dark:bg-green-600';
          break;
        case MilestoneStatus.InProgress:
        case MilestoneStatus.UnderReview:
          color = 'bg-blue-500 dark:bg-blue-600';
          break;
        case MilestoneStatus.Rejected:
          color = 'bg-red-500 dark:bg-red-600';
          break;
        default:
          color = 'bg-gray-400 dark:bg-gray-600';
      }

      // Check if overdue
      const isOverdue =
        milestone.status !== MilestoneStatus.Approved &&
        today > milestone.dueDate;

      if (isOverdue) {
        color = 'bg-red-600 dark:bg-red-700';
      }

      return {
        milestone,
        left,
        width,
        color,
        isOverdue,
      };
    });
  }, [milestones, startDate, endDate, totalDays, today]);

  return (
    <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6">
      <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-6">
        Diagramme de Gantt
      </h2>

      {/* Timeline Header */}
      <div className="relative mb-8">
        {/* Timeline axis */}
        <div className="relative h-12 bg-gray-100 dark:bg-gray-700 rounded">
          {timelineMarks.map((mark, idx) => (
            <div
              key={idx}
              className="absolute top-0 h-full flex flex-col items-center"
              style={{ left: `${mark.position}%` }}
            >
              <div className="w-px h-3 bg-gray-400 dark:bg-gray-500" />
              <span className="text-xs text-gray-600 dark:text-gray-400 mt-1">
                {mark.label}
              </span>
            </div>
          ))}

          {/* Today marker */}
          {todayPosition >= 0 && todayPosition <= 100 && (
            <div
              className="absolute top-0 h-full flex flex-col items-center z-10"
              style={{ left: `${todayPosition}%` }}
            >
              <div className="w-0.5 h-full bg-red-500" />
              <div className="absolute -top-6 px-2 py-1 bg-red-500 text-white text-xs rounded whitespace-nowrap">
                Aujourd'hui
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Gantt Bars */}
      <div className="space-y-4">
        {ganttBars.map((bar, idx) => (
          <div key={idx} className="relative">
            {/* Milestone Label */}
            <div className="flex items-center mb-2">
              <span className="text-xs font-medium text-gray-500 dark:text-gray-400 w-8">
                #{bar.milestone.order}
              </span>
              <span className="text-sm font-medium text-gray-900 dark:text-white flex-1">
                {bar.milestone.title}
              </span>
              <span
                className={`px-2 py-0.5 rounded-full text-xs font-medium ${getMilestoneStatusColor(
                  bar.milestone.status
                )}`}
              >
                {MilestoneStatus[bar.milestone.status]}
              </span>
            </div>

            {/* Bar Track */}
            <div className="relative h-8 bg-gray-100 dark:bg-gray-700 rounded">
              {/* Milestone Bar */}
              <div
                className={`absolute top-1 h-6 ${bar.color} rounded shadow-sm transition-all hover:shadow-md cursor-pointer group`}
                style={{
                  left: `${bar.left}%`,
                  width: `${bar.width}%`,
                }}
              >
                {/* Tooltip */}
                <div className="absolute bottom-full left-0 mb-2 hidden group-hover:block z-20">
                  <div className="bg-gray-900 text-white text-xs rounded-lg p-3 shadow-lg whitespace-nowrap">
                    <div className="font-medium mb-1">{bar.milestone.title}</div>
                    <div className="text-gray-300">
                      Échéance:{' '}
                      {bar.milestone.dueDate.toLocaleDateString('fr-FR', {
                        day: 'numeric',
                        month: 'short',
                        year: 'numeric',
                      })}
                    </div>
                    <div className="text-gray-300">
                      Montant:{' '}
                      {(Number(bar.milestone.amount) / 1e18).toLocaleString('fr-FR', {
                        maximumFractionDigits: 0,
                      })}{' '}
                      DAOS
                    </div>
                    {bar.isOverdue && (
                      <div className="text-red-400 font-medium mt-1">
                        ⚠️ En retard
                      </div>
                    )}
                  </div>
                </div>

                {/* Progress indicator for in-progress milestones */}
                {bar.milestone.status === MilestoneStatus.InProgress && (
                  <div className="absolute inset-0 rounded overflow-hidden">
                    <div className="h-full bg-blue-400 dark:bg-blue-500 animate-pulse" style={{ width: '50%' }} />
                  </div>
                )}

                {/* Completion checkmark */}
                {bar.milestone.status === MilestoneStatus.Approved && (
                  <div className="absolute right-1 top-1/2 -translate-y-1/2">
                    <svg
                      className="w-4 h-4 text-white"
                      fill="none"
                      viewBox="0 0 24 24"
                      stroke="currentColor"
                    >
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth={3}
                        d="M5 13l4 4L19 7"
                      />
                    </svg>
                  </div>
                )}
              </div>

              {/* Due date marker */}
              <div
                className="absolute top-0 h-8 w-px bg-gray-400 dark:bg-gray-500"
                style={{
                  left: `${((differenceInDays(bar.milestone.dueDate, startDate) / totalDays) * 100)}%`,
                }}
              />
            </div>

            {/* Deliverables count */}
            <div className="text-xs text-gray-500 dark:text-gray-400 mt-1 ml-8">
              {bar.milestone.deliverables.length} livrable(s)
            </div>
          </div>
        ))}
      </div>

      {/* Legend */}
      <div className="mt-8 pt-6 border-t border-gray-200 dark:border-gray-700">
        <div className="text-sm font-medium text-gray-700 dark:text-gray-300 mb-3">
          Légende
        </div>
        <div className="flex flex-wrap gap-4 text-xs">
          <div className="flex items-center space-x-2">
            <div className="w-6 h-3 bg-gray-400 dark:bg-gray-600 rounded" />
            <span className="text-gray-600 dark:text-gray-400">En attente</span>
          </div>
          <div className="flex items-center space-x-2">
            <div className="w-6 h-3 bg-blue-500 dark:bg-blue-600 rounded" />
            <span className="text-gray-600 dark:text-gray-400">En cours/Révision</span>
          </div>
          <div className="flex items-center space-x-2">
            <div className="w-6 h-3 bg-green-500 dark:bg-green-600 rounded" />
            <span className="text-gray-600 dark:text-gray-400">Approuvé</span>
          </div>
          <div className="flex items-center space-x-2">
            <div className="w-6 h-3 bg-red-600 dark:bg-red-700 rounded" />
            <span className="text-gray-600 dark:text-gray-400">En retard/Rejeté</span>
          </div>
          <div className="flex items-center space-x-2">
            <div className="w-0.5 h-3 bg-red-500" />
            <span className="text-gray-600 dark:text-gray-400">Aujourd'hui</span>
          </div>
        </div>
      </div>

      {/* Empty State */}
      {ganttBars.length === 0 && (
        <div className="text-center py-12 text-gray-500 dark:text-gray-400">
          <svg
            className="w-16 h-16 mx-auto mb-4"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
            />
          </svg>
          <p className="text-sm">Aucun jalon défini pour cette mission</p>
        </div>
      )}
    </div>
  );
}
